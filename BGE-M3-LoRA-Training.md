# BGE-M3 LoRA Fine-Tuning Pipeline

Documentation for `setup_and_run.sh` and `train.py`.

---

## Overview

This pipeline fine-tunes [BAAI/bge-m3](https://huggingface.co/BAAI/bge-m3) for document embedding using LoRA (Low-Rank Adaptation). It is designed to run on a multi-GPU RunPod instance and produces four artifacts uploaded to HuggingFace: a LoRA adapter, a merged full model, a GGUF quantized model, and training checkpoints.

```
setup_and_run.sh          ← outer shell: environment, orchestration, upload, pod teardown
    └── train.py          ← inner Python: dataset, model, LoRA, training loop
```

`setup_and_run.sh` calls `train.py` via `torchrun`. Everything before and after that call is handled by the shell script.

---

## Files

### `setup_and_run.sh`

The full pipeline driver. Runs once per training job. Takes a single argument — the run name — and executes eight phases in sequence.

### `train.py`

The training script. Called by `setup_and_run.sh` but can also be invoked directly (e.g. for resuming). Handles dataset loading, model setup, LoRA application, and the training loop.

---

## Prerequisites

- RunPod instance with 4× A100 80GB GPUs
- Environment variables set before running:
  - `HF_TOKEN` — HuggingFace token with write access
  - `RUNPOD_API_KEY` — RunPod API key (used for auto pod teardown at the end)
- A base model already on HuggingFace: `keisuke-miyako/bge-m3-doc-R1-merged`
- A training dataset on HuggingFace with columns `query`, `pos` (list), `neg` (list)

---

## Usage

### Normal fresh run

```bash
bash setup_and_run.sh r2
```

The run name (`r2`, `r3`, etc.) is used as a suffix for all HuggingFace repo names and local directories.

### Resume from checkpoint

Skip `setup_and_run.sh` and call `torchrun` directly, passing the checkpoint path as the 5th argument:

```bash
export NCCL_P2P_DISABLE=1
export NCCL_IB_DISABLE=1
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

torchrun \
    --nproc_per_node=4 \
    --master_addr=localhost \
    --master_port=29500 \
    /workspace/train.py r2 \
        /workspace/bge_m3/r2 \
        keisuke-miyako/bge-m3-doc-r2-checkpoints \
        keisuke-miyako/doc-2026-0609 \
        /workspace/bge_m3/r2/checkpoints/checkpoint-1900 \
    2>&1 | tee /workspace/train_r2_resume.log
```

When resuming, `train.py` loads the LoRA weights from `adapter_model.safetensors` inside the checkpoint directory and restores the optimizer state, scheduler position, and RNG state so training continues exactly where it left off.

---

## Pipeline Phases (`setup_and_run.sh`)

### Phase 1 — PyTorch + CUDA check

Detects whether CUDA is already working. If yes, skips reinstallation entirely. If no, detects the driver CUDA version via `nvidia-smi` and installs the appropriate torch wheel (`cu124` for CUDA 12.x, `cu118` for CUDA 11.x). Verifies CUDA is functional after any install.

### Phase 2 — Package installation

Installs all Python dependencies while pinning the current torch version to a constraint file (`/tmp/torch_pin.txt`) so pip cannot accidentally downgrade or replace torch. Verifies CUDA is still intact after installation.

Installed packages:
- `sentence-transformers>=3.3.0,<4.0`
- `datasets>=2.20`
- `peft>=0.13,<0.15`
- `transformers==4.46.3`
- `accelerate>=0.34`
- `huggingface_hub>=0.24`
- `matplotlib`

### Phase 3 — llama.cpp

Clones `llama.cpp` to `/workspace/llama.cpp` (skips if already present). Installs only the converter's dependencies (`gguf`, `sentencepiece`, `protobuf`) — deliberately avoids `llama.cpp`'s full `requirements.txt` because it contains a torch line that would break the pin.

### Phase 4 — Authentication

Logs into HuggingFace and creates (or confirms existence of) the four output repos:
- `keisuke-miyako/bge-m3-doc-{RN}-adapter`
- `keisuke-miyako/bge-m3-doc-{RN}-merged`
- `keisuke-miyako/bge-m3-doc-{RN}-gguf`
- `keisuke-miyako/bge-m3-doc-{RN}-checkpoints`

Also installs and configures `runpodctl` for pod teardown at the end.

### Phase 5 — Training

Sets NCCL environment variables for PCIe topology (no NVLink) and launches `train.py` via `torchrun` across all available GPUs. Output is tee'd to `/workspace/train_{RN}.log`.

### Phase 5b — Loss plot

After training, reads `trainer_state.json` from the latest local checkpoint (or falls back to fetching it from HuggingFace if local checkpoints are missing). Generates:
- `adapter/training-loss.csv` — step/loss pairs
- `adapter/training-loss.png` — loss curve chart

### Phase 6 — LoRA merge

Loads the fine-tuned LoRA adapter on top of `bge-m3-doc-r1-merged`, calls `merge_and_unload()` to produce a single merged model, and saves it to `{WORK_DIR}/merged`. Performs a sanity check by verifying the query layer weights actually changed after merging.

### Phase 7 — GGUF export

Converts the merged model to GGUF format at `q8_0` quantization using `llama.cpp/convert_hf_to_gguf.py`. Output: `{WORK_DIR}/gguf/bge-m3-doc-{RN}-q8_0.gguf`.

### Phase 8 — Upload

Uploads all four directories to their respective HuggingFace repos using `upload_folder`. If any upload fails, the script exits with an error listing which repos failed.

### Teardown

Calls `runpodctl remove pod {POD_ID}` to terminate and delete the pod automatically after a successful run.

---

## Training Script (`train.py`)

### Arguments

| Position | Name | Default | Description |
|---|---|---|---|
| 1 | `RN` | `r2` | Run name, used as suffix for repo and directory names |
| 2 | `WORK_DIR` | `/workspace/bge_m3/{RN}` | Root directory for all outputs |
| 3 | `CKPT_REPO` | `{HF_USER}/bge-m3-doc-{RN}-checkpoints` | HuggingFace repo for checkpoint pushes |
| 4 | `HF_DATASET` | `{HF_USER}/doc-2026-0609` | HuggingFace dataset to train on |
| 5 | `RESUME` | `None` | Path to checkpoint directory to resume from |

### Dataset processing

The dataset is expected to have columns `query`, `pos` (list of positive passages), and `neg` (list of negative passages). For each row, `make_training_pairs` pairs every positive with one randomly sampled negative, producing `(anchor, positive, negative)` triplets. The random negative selection rotates across epochs, providing implicit hard negative augmentation over the course of training.

### Model setup

Loads `bge-m3-doc-R1-merged` as a `SentenceTransformer` in `bfloat16`. Extracts the transformer backbone and wraps it with PEFT LoRA:

| Parameter | Value |
|---|---|
| Rank (`r`) | 32 |
| Alpha | 64 |
| Dropout | 0.05 |
| Target modules | `query`, `key`, `value`, `dense` |
| Trainable parameters | ~14.2M out of 582M (2.44%) |

### Loss function

`MultipleNegativesSymmetricRankingLoss` (bidirectional InfoNCE) with scale 15.0 (equivalent to temperature 0.067). The symmetric variant adds a passage→query direction on top of the standard query→passage, doubling the learning signal per batch.

### Hyperparameters

| Parameter | Value |
|---|---|
| Per-device batch size | 8 |
| Gradient accumulation | 2 |
| Effective batch size | 8 × 2 × 4 GPUs = 64 |
| Learning rate | 1.5e-5 |
| LR scheduler | Cosine |
| Warmup | 10% of total steps |
| Weight decay | 0.01 |
| Epochs | 5 |
| Precision | bfloat16 |
| Gradient checkpointing | Yes (non-reentrant) |

### Checkpointing

Saves every 500 steps, keeps the last 5 checkpoints. Each checkpoint is pushed to the HuggingFace checkpoints repo immediately after saving. Each checkpoint directory contains:
- `adapter_model.safetensors` — LoRA weights at that step
- `optimizer.pt` — optimizer state
- `scheduler.pt` — LR scheduler state
- `rng_state_{0..N}.pth` — per-GPU RNG state for exact reproducibility
- `trainer_state.json` — loss history and training metadata
- Tokenizer files

### `RobustTrainer`

A subclass of `SentenceTransformerTrainer` that fixes two issues:

**`_load_from_checkpoint`** — The default implementation tries to reload the checkpoint via `SentenceTransformer(checkpoint_path)`, which fails because checkpoint directories contain a LoRA adapter (not a full sentence-transformers model) and have no `model_type` in their `config.json`. The override loads LoRA weights directly via `set_peft_model_state_dict`, bypassing this entirely.

**`_save`** — Wraps the parent save in a retry loop (5 attempts, 10s delay) that catches `OSError` with `errno=5`. On RunPod, `/workspace` is a MooseFS network filesystem that occasionally returns transient I/O errors during writes. Without this retry, a single network blip during a checkpoint save crashes the entire training job.

---

## Directory structure

```
/workspace/
├── train.py
├── setup_and_run.sh
├── train_{RN}.log
├── llama.cpp/
└── bge_m3/
    └── {RN}/
        ├── adapter/                   ← final LoRA adapter (after training)
        │   ├── adapter_model.safetensors
        │   ├── adapter_config.json
        │   ├── tokenizer files
        │   ├── training-loss.csv
        │   ├── training-loss.png
        │   └── README.md
        ├── merged/                    ← merged full model (phase 6)
        ├── gguf/                      ← GGUF export (phase 7)
        │   └── bge-m3-doc-{RN}-q8_0.gguf
        └── checkpoints/               ← training checkpoints
            ├── adapter_model.safetensors   ← top-level (legacy, from interrupted runs)
            ├── checkpoint-500/
            ├── checkpoint-1000/
            └── checkpoint-1500/
```

---

## HuggingFace repos produced

| Repo | Contents |
|---|---|
| `bge-m3-doc-{RN}-adapter` | LoRA adapter weights + tokenizer + loss chart |
| `bge-m3-doc-{RN}-merged` | Full merged model (base + LoRA), float16 |
| `bge-m3-doc-{RN}-gguf` | GGUF q8_0 quantized model for llama.cpp |
| `bge-m3-doc-{RN}-checkpoints` | All training checkpoints with optimizer state |

---

## Common failure modes

**`OSError: [Errno 5] Input/output error` during checkpoint save**
MooseFS transient write failure. Fixed by `RobustTrainer._save` retry logic. If it persists across all 5 retries, check `dmesg` for NFS errors and consider recreating the volume.

**`ValueError: Unrecognized model` when resuming**
The default `SentenceTransformerTrainer._load_from_checkpoint` cannot load a LoRA checkpoint. Fixed by `RobustTrainer._load_from_checkpoint`. Ensure you are using the updated `train.py`.

**`ValueError: Unrecognized model in bge-m3-doc-{RN}-merged` at startup**
The merged model from a previous run doesn't exist yet (first run of a new `RN`). The script is trying to load its own output as input. This is expected on first run and not an error — the model loads from `bge-m3-doc-R1-merged` (the R1 base) correctly.

**Training starts from step 0 despite passing a checkpoint**
The checkpoint directory may be incomplete (missing `optimizer.pt`). Check the checkpoint contents with `ls`. Use the most recent checkpoint that has `optimizer.pt`, `scheduler.pt`, and `rng_state_*.pth`.
