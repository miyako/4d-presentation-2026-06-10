import os, torch, gc, json
from huggingface_hub import snapshot_download, login
from transformers import AutoModel
from peft import LoraConfig, get_peft_model
from FlagEmbedding.finetune.embedder.encoder_only.m3 import (
    EncoderOnlyEmbedderM3DataArguments,
    EncoderOnlyEmbedderM3TrainingArguments,
    EncoderOnlyEmbedderM3ModelArguments,
    EncoderOnlyEmbedderM3Runner,
)

import sys
Rn         = sys.argv[1] if len(sys.argv) > 1 else "r14"
RESUME     = sys.argv[2].lower() == "true" if len(sys.argv) > 2 else False  # FIX 1: removed hardcoded overrides below
CHECKPOINT = sys.argv[3] if len(sys.argv) > 3 else ""

TRAIN_FILE    = f"/workspace/bge_legal/{Rn}/training.jsonl"
WORK_DIR      = "/workspace/bge_legal"
DRIVE_ADAPTER = f"/workspace/bge_legal/{Rn}/lora_adapter"

# ── Hugging Face dataset ──────────────────────────────────────────────────────
HF_DATASET = 'keisuke-miyako/legal-euro-2026-0524'
HF_TOKEN   = os.environ.get("HF_TOKEN", "")
# ─────────────────────────────────────────────────────────────────────────────

# ── Training hyperparameters ──────────────────────────────────────────────────
PER_DEVICE_BATCH    = 32
GRAD_ACCUM          = 1
EPOCHS              = 3
LEARNING_RATE       = 5e-6
LORA_RANK           = 64
LORA_ALPHA          = 64   # alpha=rank (scale=1.0)
LORA_TARGET_MODULES = ['query', 'key', 'value', 'dense']
SUB_BATCH_SIZE      = 32   # match per_device_batch
PASSAGE_MAX_LEN     = 1024
TEMPERATURE         = 0.07 # was 0.05
SAFE_GROUP          = 6    # was 7
NUM_GPUS            = 4
QUERY_MAX_LEN       = 64
# ─────────────────────────────────────────────────────────────────────────────

# ── Download dataset from Hugging Face (rank 0 only) ─────────────────────────
LOCAL_RANK = int(os.environ.get("LOCAL_RANK", 0))
if LOCAL_RANK == 0:
    if os.path.exists(TRAIN_FILE):
        print(f"Dataset already exists, skipping download: {TRAIN_FILE}")
    else:
        from datasets import load_dataset
        print(f"Logging in to Hugging Face ...")
        if HF_TOKEN:
            login(token=HF_TOKEN, add_to_git_credential=False)
        print(f"Downloading dataset: {HF_DATASET}")
        os.makedirs(os.path.dirname(TRAIN_FILE), exist_ok=True)
        ds = load_dataset(HF_DATASET)
        train_split = ds['train']
        print(f"Rows: {len(train_split)}  |  Columns: {train_split.column_names}")

        def to_list(value):
            if isinstance(value, list):
                return [str(v) for v in value]
            if isinstance(value, str):
                return [value]
            return [str(value)]

        with open(TRAIN_FILE, 'w', encoding='utf-8', newline='\n') as f:
            for row in train_split:
                record = {
                    'query': str(row['query']),
                    'pos':   to_list(row['pos']),
                    'neg':   to_list(row['neg']),
                }
                f.write(json.dumps(record, ensure_ascii=False) + '\n')
        print(f"Dataset written to {TRAIN_FILE}")

if LOCAL_RANK != 0:
    import time
    print(f"[rank {LOCAL_RANK}] Waiting for dataset ...")
    while not os.path.exists(TRAIN_FILE):
        time.sleep(3)
    time.sleep(2)
    print(f"[rank {LOCAL_RANK}] Dataset ready.")
# ─────────────────────────────────────────────────────────────────────────────

with open(TRAIN_FILE, encoding="utf-8") as f:
    records = [json.loads(line) for line in f]

lora_cfg = LoraConfig(
    r=LORA_RANK,
    lora_alpha=LORA_ALPHA,
    target_modules=LORA_TARGET_MODULES,
    lora_dropout=0.1,
    bias="none",
    task_type="FEATURE_EXTRACTION",
)

class LoRAM3Runner(EncoderOnlyEmbedderM3Runner):

    @staticmethod
    def get_model(model_name_or_path, trust_remote_code=False, colbert_dim=-1,
                  cache_dir=None, torch_dtype=None):
        cache_folder = cache_dir or os.path.join(
            os.getenv("HF_HOME", os.path.expanduser("~/.cache/huggingface")), "hub"
        )
        if not os.path.exists(model_name_or_path):
            model_name_or_path = snapshot_download(
                repo_id=model_name_or_path,
                cache_dir=cache_folder,
                ignore_patterns=["flax_model.msgpack", "rust_model.ot", "tf_model.h5"]
            )

        # Load base transformer
        model = AutoModel.from_pretrained(
            model_name_or_path,
            cache_dir=cache_folder,
            trust_remote_code=trust_remote_code,
            torch_dtype=torch_dtype,
        )

        # Create projection heads (shapes must match checkpoint)
        colbert_out = model.config.hidden_size if colbert_dim <= 0 else colbert_dim
        colbert_linear = torch.nn.Linear(
            in_features=model.config.hidden_size,
            out_features=colbert_out,
            dtype=torch_dtype,
        )
        sparse_linear = torch.nn.Linear(
            in_features=model.config.hidden_size,
            out_features=1,
            dtype=torch_dtype,
        )

        # ── Load pre-trained colbert/sparse weights from BGE-M3 checkpoint ──────
        # CRITICAL: use_self_distill=True uses colbert+sparse scores as a teacher
        # signal. Random init here means garbage teacher → dense scores degrade.
        # We load the full checkpoint state dict and splice in the projection weights.
        import glob
        state_dict = None

        # Prefer safetensors (sharded or single)
        st_files = sorted(glob.glob(os.path.join(model_name_or_path, "*.safetensors")))
        if st_files:
            try:
                from safetensors.torch import load_file
                state_dict = {}
                for f in st_files:
                    state_dict.update(load_file(f, device="cpu"))
                print(f"Loaded checkpoint from {len(st_files)} safetensors shard(s)")
            except Exception as e:
                print(f"WARNING: safetensors load failed ({e}), trying pytorch_model.bin")

        if state_dict is None:
            pt_file = os.path.join(model_name_or_path, "pytorch_model.bin")
            if os.path.exists(pt_file):
                state_dict = torch.load(pt_file, map_location="cpu")
                print("Loaded checkpoint from pytorch_model.bin")
            else:
                print("WARNING: No checkpoint found — colbert/sparse heads will use random init")

        if state_dict is not None:
            for head_name, head_module in [("colbert_linear", colbert_linear),
                                           ("sparse_linear",  sparse_linear)]:
                prefix    = head_name + "."
                head_dict = {k[len(prefix):]: v for k, v in state_dict.items()
                             if k.startswith(prefix)}
                if head_dict:
                    # Cast to match the linear layer's dtype if needed
                    if torch_dtype is not None:
                        head_dict = {k: v.to(torch_dtype) for k, v in head_dict.items()}
                    head_module.load_state_dict(head_dict, strict=True)
                    print(f"  ✓ {head_name}: loaded pre-trained weights "
                          f"({list(head_dict['weight'].shape)})")
                else:
                    print(f"  ✗ WARNING: {head_name} not found in checkpoint — random init")
        # ─────────────────────────────────────────────────────────────────────────

        return {"model": model, "colbert_linear": colbert_linear, "sparse_linear": sparse_linear}

    def load_tokenizer_and_model(self):
        tokenizer, model = super().load_tokenizer_and_model()
        if RESUME and CHECKPOINT:
            print("Resuming LoRA from checkpoint: " + CHECKPOINT)
            from peft import PeftModel
            model.model = PeftModel.from_pretrained(model.model, CHECKPOINT, is_trainable=True)
        else:
            print("Starting fresh LoRA ...")
            model.model = get_peft_model(model.model, lora_cfg)
        model.model.print_trainable_parameters()
        if self.training_args.gradient_checkpointing:
            model.model.enable_input_require_grads()

        # ── Fix cross-device colbert_vecs shape mismatch ──────────────────────
        # colbert_vecs shape = (batch, seq_len, dim). Different GPUs pad to
        # different seq_len, causing all_gather to fail. Padding inputs to fixed
        # lengths ensures identical shapes across all 3 GPUs before gathering.
        pad_id = tokenizer.pad_token_id
        original_forward = model.forward

        def pad_features(features, max_len):
            if features is None:
                return features
            if isinstance(features, list):
                # list of sub-feature dicts — pad each one to the same max_len
                for feat in features:
                    for key in ['input_ids', 'attention_mask', 'token_type_ids']:
                        if key not in feat:
                            continue
                        t = feat[key]
                        pad_len = max_len - t.shape[-1]
                        if pad_len > 0:
                            fill = pad_id if key == 'input_ids' else 0
                            feat[key] = torch.nn.functional.pad(t, (0, pad_len), value=fill)
                return features
            # single dict
            for key in ['input_ids', 'attention_mask', 'token_type_ids']:
                if key not in features:
                    continue
                t = features[key]
                pad_len = max_len - t.shape[-1]
                if pad_len > 0:
                    fill = pad_id if key == 'input_ids' else 0
                    features[key] = torch.nn.functional.pad(t, (0, pad_len), value=fill)
            return features

        def padded_forward(queries=None, passages=None, teacher_scores=None, no_in_batch_neg_flag=False):
            queries  = pad_features(queries,  QUERY_MAX_LEN)   # FIX: was hardcoded 64, now uses shared constant
            passages = pad_features(passages, PASSAGE_MAX_LEN)
            return original_forward(queries=queries, passages=passages,
                                    teacher_scores=teacher_scores,
                                    no_in_batch_neg_flag=no_in_batch_neg_flag)

        model.forward = padded_forward
        # ─────────────────────────────────────────────────────────────────────

        return tokenizer, model

    def load_trainer(self):
        trainer = super().load_trainer()
        if not hasattr(trainer, "tokenizer") or trainer.tokenizer is None:
            trainer.tokenizer = self.tokenizer
        return trainer

    def run(self):
        self.trainer = self.load_trainer()
        if RESUME and CHECKPOINT:
            self.trainer._load_from_checkpoint = lambda checkpoint_dir, model=None: None
            self.trainer.train(resume_from_checkpoint=CHECKPOINT)
        else:
            self.trainer.train()
        self.trainer.save_model()

gc.collect()
torch.cuda.empty_cache()

total_steps = len(records) * EPOCHS // (PER_DEVICE_BATCH * GRAD_ACCUM * NUM_GPUS)

model_args = EncoderOnlyEmbedderM3ModelArguments(model_name_or_path="BAAI/bge-m3")

data_args = EncoderOnlyEmbedderM3DataArguments(
    train_data=[TRAIN_FILE],
    train_group_size=SAFE_GROUP,
    query_max_len=QUERY_MAX_LEN,   # FIX: was hardcoded 64, now uses shared constant
    passage_max_len=PASSAGE_MAX_LEN,
    cache_path=os.path.join(WORK_DIR, "cache"),
)

training_args = EncoderOnlyEmbedderM3TrainingArguments(
    output_dir=DRIVE_ADAPTER,
    num_train_epochs=EPOCHS,
    per_device_train_batch_size=PER_DEVICE_BATCH,
    gradient_accumulation_steps=GRAD_ACCUM,
    learning_rate=LEARNING_RATE,
    lr_scheduler_type="cosine",                          # FIX 8: was default linear — cosine works better for retrieval
    warmup_steps=int(0.05 * total_steps),                # FIX 7: was 10% warmup — 5% is sufficient for LoRA
    max_grad_norm=1.0, # Or 0.5 if you see spikes again
    weight_decay=0.01,
    bf16=True,
    fp16=False,
    gradient_checkpointing=True,
    gradient_checkpointing_kwargs={'use_reentrant': False},
    sub_batch_size=SUB_BATCH_SIZE,
    normalize_embeddings=True,
    sentence_pooling_method="cls",
    temperature=TEMPERATURE,
    negatives_cross_device=True,
    unified_finetuning=True,
    use_self_distill=True,
    logging_steps=10,
    save_strategy="steps",
    save_steps=100,
    save_total_limit=3,
    dataloader_num_workers = 8, # was 4
    remove_unused_columns=False,
    report_to="none",
)

runner = LoRAM3Runner(
    model_args=model_args,
    data_args=data_args,
    training_args=training_args,
)
runner.run()

runner.model.model.save_pretrained(DRIVE_ADAPTER)
print("LoRA adapter saved -> " + DRIVE_ADAPTER)
