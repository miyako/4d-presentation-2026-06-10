#!/usr/bin/env python3
"""
BGE-M3 fine-tuning
  - sentence-transformers 3.x + MultipleNegativesSymmetricRankingLoss
  - LoRA via PEFT (rank 32, targets query/key/value/dense)
  - Multi-GPU via torchrun (DDP handled by HF Trainer under the hood)
  - Checkpoints every 100 steps, pushed to HuggingFace

Usage (via torchrun in setup_and_run.sh):
  torchrun --nproc_per_node=N train.py <RN> <WORK_DIR> <CKPT_REPO> <HF_DATASET> [RESUME_CKPT]
"""
import os, sys, random, logging, time
import torch
from datasets import load_dataset
from huggingface_hub import login
from peft import LoraConfig, get_peft_model, TaskType
from sentence_transformers import SentenceTransformer, SentenceTransformerTrainer
from sentence_transformers.losses import MultipleNegativesSymmetricRankingLoss
from sentence_transformers.training_args import SentenceTransformerTrainingArguments


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)s  %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger(__name__)

# ── Args ──────────────────────────────────────────────────────────────────────
HF_USER    = "keisuke-miyako"
RN         = sys.argv[1] if len(sys.argv) > 1 else "r2"
WORK_DIR   = sys.argv[2] if len(sys.argv) > 2 else f"/workspace/bge_m3/{RN}"
CKPT_REPO  = sys.argv[3] if len(sys.argv) > 3 else f"{HF_USER}/bge-m3-doc-{RN}-checkpoints"
HF_DATASET = sys.argv[4] if len(sys.argv) > 4 else f"{HF_USER}/doc-2026-0612"
RESUME     = sys.argv[5] if len(sys.argv) > 5 else None   # e.g. /workspace/.../checkpoint-1900
HF_TOKEN   = os.environ.get("HF_TOKEN", "")

ADAPTER_DIR = os.path.join(WORK_DIR, "adapter")
CKPT_DIR    = os.path.join(WORK_DIR, "checkpoints")
os.makedirs(ADAPTER_DIR, exist_ok=True)
os.makedirs(CKPT_DIR, exist_ok=True)

# ── Distributed setup ─────────────────────────────────────────────────────────
LOCAL_RANK = int(os.environ.get("LOCAL_RANK", 0))
WORLD_SIZE = int(os.environ.get("WORLD_SIZE", 1))
IS_MAIN    = LOCAL_RANK == 0

# ─────────────────────────────────────────────────────────────────────────────
# Hyperparameters — tuned for 4 × A100 80GB PCIe
# Effective batch = PER_DEVICE_BATCH × GRAD_ACCUM × WORLD_SIZE
#                 = 8 × 2 × 4 = 64
# ─────────────────────────────────────────────────────────────────────────────
PER_DEVICE_BATCH = 8
GRAD_ACCUM       = 2
LEARNING_RATE    = 1.5e-5
EPOCHS           = 5
WARMUP_RATIO     = 0.10

LORA_R       = 32
LORA_ALPHA   = 64
LORA_DROPOUT = 0.05
LORA_TARGETS = ["query", "key", "value", "dense"]
MNRL_SCALE   = 15.0


def make_training_pairs(example):
    query    = example["query"]
    pos_list = example["pos"] if isinstance(example["pos"], list) else [example["pos"]]
    neg_list = example["neg"] if isinstance(example["neg"], list) else [example["neg"]]

    if not pos_list or not neg_list:
        return {"anchor": [], "positive": [], "negative": []}

    anchors, positives, negatives = [], [], []
    for pos in pos_list:
        neg = random.choice(neg_list)
        anchors.append(query)
        positives.append(pos)
        negatives.append(neg)

    return {"anchor": anchors, "positive": positives, "negative": negatives}


class RobustTrainer(SentenceTransformerTrainer):
    """
    Overrides two methods:
      _load_from_checkpoint: loads LoRA weights directly (bypasses broken
                             SentenceTransformer(checkpoint_path) reload)
      _save:                 retries on MooseFS Errno 5 transient I/O errors
    """

    def _load_from_checkpoint(self, checkpoint_path):
        from safetensors.torch import load_file
        from peft import set_peft_model_state_dict

        safe = os.path.join(checkpoint_path, "adapter_model.safetensors")
        if os.path.exists(safe):
            state = load_file(safe)
            set_peft_model_state_dict(self.model[0].auto_model, state)
            if IS_MAIN:
                log.info(f"Restored LoRA weights from {safe}")
        else:
            if IS_MAIN:
                log.warning(f"No adapter_model.safetensors in {checkpoint_path}, skipping weight restore")

    def _save(self, output_dir, state_dict=None):
        for attempt in range(5):
            try:
                super()._save(output_dir, state_dict=state_dict)
                return
            except OSError as e:
                if e.errno == 5 and attempt < 4:
                    log.warning(f"MooseFS I/O error on save attempt {attempt+1}/5, retrying in 10s...")
                    time.sleep(10)
                else:
                    raise


def main():
    if IS_MAIN:
        if HF_TOKEN:
            login(token=HF_TOKEN, add_to_git_credential=False)
        log.info(f"Run: {RN}  |  GPUs: {torch.cuda.device_count()}  |  world_size: {WORLD_SIZE}")
        log.info(f"Dataset: {HF_DATASET}")
        log.info(f"Effective batch: {PER_DEVICE_BATCH} × {GRAD_ACCUM} × {WORLD_SIZE} = "
                 f"{PER_DEVICE_BATCH * GRAD_ACCUM * WORLD_SIZE}")
        if RESUME:
            log.info(f"Resuming from: {RESUME}")

    # ── Dataset ───────────────────────────────────────────────────────────────
    if IS_MAIN:
        log.info("Loading dataset ...")

    raw_ds = load_dataset(HF_DATASET, split="train", token=HF_TOKEN if HF_TOKEN else None)

    if IS_MAIN:
        log.info(f"Raw rows: {len(raw_ds)}  columns: {raw_ds.column_names}")

    train_ds = raw_ds.map(
        make_training_pairs,
        batched=False,
        remove_columns=raw_ds.column_names,
        desc="Building triplets",
    )
    train_ds = train_ds.filter(lambda x: len(x["anchor"]) > 0)
    train_ds = train_ds.map(
        lambda batch: {
            "anchor":   [a for row in batch["anchor"]   for a in row],
            "positive": [p for row in batch["positive"] for p in row],
            "negative": [n for row in batch["negative"] for n in row],
        },
        batched=True,
        remove_columns=train_ds.column_names,
        desc="Flattening triplets",
    )

    if IS_MAIN:
        log.info(f"Training triplets: {len(train_ds)}")

    # ── Model ─────────────────────────────────────────────────────────────────
    if IS_MAIN:
        log.info("Loading base model ...")

    model = SentenceTransformer(
        f"{HF_USER}/bge-m3-doc-R1-merged",
        model_kwargs={"torch_dtype": torch.bfloat16},
    )

    lora_config = LoraConfig(
        task_type=TaskType.FEATURE_EXTRACTION,
        r=LORA_R,
        lora_alpha=LORA_ALPHA,
        target_modules=LORA_TARGETS,
        lora_dropout=LORA_DROPOUT,
        bias="none",
        inference_mode=False,
    )
    backbone = model[0].auto_model
    backbone_lora = get_peft_model(backbone, lora_config)
    model[0].auto_model = backbone_lora

    if IS_MAIN:
        backbone_lora.print_trainable_parameters()

    loss = MultipleNegativesSymmetricRankingLoss(model, MNRL_SCALE)

    # ── Training args ─────────────────────────────────────────────────────────
    total_steps  = (len(train_ds) * EPOCHS) // (PER_DEVICE_BATCH * GRAD_ACCUM * WORLD_SIZE)
    warmup_steps = max(100, int(total_steps * WARMUP_RATIO))

    if IS_MAIN:
        log.info(f"Total steps ~{total_steps}  warmup {warmup_steps}")

    training_args = SentenceTransformerTrainingArguments(
        output_dir=CKPT_DIR,
        run_name=RN,
        num_train_epochs=EPOCHS,
        per_device_train_batch_size=PER_DEVICE_BATCH,
        gradient_accumulation_steps=GRAD_ACCUM,
        learning_rate=LEARNING_RATE,
        warmup_steps=warmup_steps,
        weight_decay=0.01,
        lr_scheduler_type="cosine",
        bf16=True,
        fp16=False,
        gradient_checkpointing=True,
        gradient_checkpointing_kwargs={"use_reentrant": False},
        ddp_find_unused_parameters=True,
        save_strategy="steps",
        save_steps=500,
        save_total_limit=5,
        push_to_hub=True,
        hub_model_id=CKPT_REPO,
        hub_strategy="checkpoint",
        hub_token=HF_TOKEN if HF_TOKEN else None,
        logging_strategy="steps",
        logging_steps=10,
        report_to="none",
        dataloader_num_workers=4,
        remove_unused_columns=False,
    )

    # ── Trainer ───────────────────────────────────────────────────────────────
    trainer = RobustTrainer(
        model=model,
        args=training_args,
        train_dataset=train_ds,
        loss=loss,
    )

    trainer.train(resume_from_checkpoint=RESUME)

    # ── Save final adapter ────────────────────────────────────────────────────
    if IS_MAIN:
        log.info(f"Saving LoRA adapter to {ADAPTER_DIR}")
        model[0].auto_model.save_pretrained(ADAPTER_DIR)
        model[0].tokenizer.save_pretrained(ADAPTER_DIR)

        with open(os.path.join(ADAPTER_DIR, "README.md"), "w") as f:
            f.write(f"""---
base_model: BAAI/bge-m3
tags:
  - doc
  - embeddings
  - peft
  - lora
---
# bge-m3-doc-{RN} LoRA adapter

LoRA adapter (r={LORA_R}) fine-tuned on 4D doc document embeddings.
Dataset: [{HF_DATASET}](https://huggingface.co/datasets/{HF_DATASET})

## Load
```python
from peft import PeftModel
from transformers import AutoModel
base = AutoModel.from_pretrained("BAAI/bge-m3")
model = PeftModel.from_pretrained(base, "{HF_USER}/bge-m3-doc-{RN}-adapter")
```
""")
        log.info(f"✓ Adapter saved: {ADAPTER_DIR}")


if __name__ == "__main__":
    main()
