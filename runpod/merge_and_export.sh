#!/bin/bash

pip install matplotlib -q

# ── BGE-M3 Legal LoRA — merge, export GGUF, upload ───────────────────────────
# Run after training completes
# Usage: bash /workspace/merge_and_export.sh r9
# ─────────────────────────────────────────────────────────────────────────────

set -e

Rn=${1:-r9}
WORK_DIR="/workspace/bge_legal"
DRIVE_ADAPTER="$WORK_DIR/$Rn/lora_adapter"
DRIVE_MERGED="$WORK_DIR/$Rn/merged"
DRIVE_GGUF="$WORK_DIR/$Rn/gguf"
HF_USER="keisuke-miyako"

echo "=== Run: $Rn ==="
echo "Adapter : $DRIVE_ADAPTER"
echo "Merged  : $DRIVE_MERGED"
echo "GGUF    : $DRIVE_GGUF"

echo ""
echo "=== 0. Plot training loss ==="
python3 - << PYEOF
import json, glob, os
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

DRIVE_ADAPTER = "$DRIVE_ADAPTER"
Rn = "$Rn"
WORK_DIR = "$WORK_DIR"

state_file = os.path.join(DRIVE_ADAPTER, "trainer_state.json")
if not os.path.exists(state_file):
    checkpoints = sorted(
        glob.glob(os.path.join(DRIVE_ADAPTER, "checkpoint-*")),
        key=lambda p: int(p.split("-")[-1])
    )
    state_file = os.path.join(checkpoints[-1], "trainer_state.json")

with open(state_file) as f:
    state = json.load(f)

log = [e for e in state["log_history"] if "loss" in e]
steps = [e["step"] for e in log]
losses = [e["loss"] for e in log]

plt.figure(figsize=(10, 5))
plt.plot(steps, losses, marker="o", markersize=2, linewidth=1.5)
plt.title(f"bge-m3-legal-lora {Rn} — Training Loss")
plt.xlabel("Step")
plt.ylabel("Loss")
plt.grid(True)
plt.tight_layout()

png_path = os.path.join(WORK_DIR, Rn, "training-loss.png")
csv_path = os.path.join(WORK_DIR, Rn, "training-loss.csv")
plt.savefig(png_path, dpi=150)
print("Chart saved -> " + png_path)

with open(csv_path, "w") as f:
    f.write("step,loss\n")
    for s, l in zip(steps, losses):
        f.write(f"{s},{l}\n")
print("CSV saved -> " + csv_path)
PYEOF

echo ""
echo "=== 1. Merge adapter ==="
python3 - << PYEOF
import torch, glob, os
from transformers import AutoModel, AutoTokenizer
from peft import PeftModel

DRIVE_ADAPTER = "$DRIVE_ADAPTER"
DRIVE_MERGED  = "$DRIVE_MERGED"

print("Loading base model ...")
base = AutoModel.from_pretrained("BAAI/bge-m3")
ref  = base.encoder.layer[0].attention.self.query.weight.detach().clone()

print("Loading adapter ...")
adapter_path = DRIVE_ADAPTER
if not os.path.exists(os.path.join(DRIVE_ADAPTER, "adapter_config.json")):
    checkpoints = sorted(
        glob.glob(os.path.join(DRIVE_ADAPTER, "checkpoint-*")),
        key=lambda p: int(p.split("-")[-1])
    )
    adapter_path = checkpoints[-1]
    print(f"Using checkpoint: {adapter_path}")
peft_model = PeftModel.from_pretrained(base, adapter_path, local_files_only=True)
merged = peft_model.merge_and_unload()

diff = (ref - merged.encoder.layer[0].attention.self.query.weight).abs().max().item()
print(f"Max weight diff: {diff:.8f}")
assert diff > 0, "Merge failed — no weight change detected"

merged.save_pretrained(DRIVE_MERGED, safe_serialization=True)
AutoTokenizer.from_pretrained("BAAI/bge-m3").save_pretrained(DRIVE_MERGED)
print("Merged saved -> " + DRIVE_MERGED)
PYEOF

echo ""
echo "=== 2. Copy tokenizer files for GGUF ==="
python3 - << PYEOF
from huggingface_hub import hf_hub_download
import shutil

DRIVE_MERGED = "$DRIVE_MERGED"
for fn in ["tokenizer.json", "tokenizer_config.json", "sentencepiece.bpe.model"]:
    src = hf_hub_download(repo_id="BAAI/bge-m3", filename=fn)
    shutil.copy(src, DRIVE_MERGED + "/" + fn)
    print("Copied " + fn)
PYEOF

echo ""
echo "=== 3. Convert to GGUF ==="
GGUF_OUT="$DRIVE_GGUF/bge-m3-legal-q8_0.gguf"
mkdir -p "$DRIVE_GGUF"
python3 /workspace/llama.cpp/convert_hf_to_gguf.py \
    "$DRIVE_MERGED" \
    --outtype q8_0 \
    --outfile "$GGUF_OUT"
echo "GGUF saved -> $GGUF_OUT"

echo "=== 3b. Fix adapter README ==="
python3 - << PYEOF
import os
readme = "$DRIVE_ADAPTER/README.md"
if os.path.exists(readme):
    with open(readme) as f:
        content = f.read()
    content = content.replace(
        content[content.find("base_model:"):content.find("\n", content.find("base_model:"))],
        "base_model: BAAI/bge-m3"
    )
    with open(readme, "w") as f:
        f.write(content)
    print("README fixed")
PYEOF

rm -rf "$DRIVE_ADAPTER"/checkpoint-*

echo ""
echo "=== 4. Upload to HuggingFace ==="
huggingface-cli upload "$HF_USER/bge-m3-legal-euro-${Rn}-adapter" \
    "$DRIVE_ADAPTER" --repo-type model
echo "Adapter uploaded"

huggingface-cli upload "$HF_USER/bge-m3-legal-euro-${Rn}-merged" \
    "$DRIVE_MERGED" --repo-type model
echo "Merged uploaded"

huggingface-cli upload "$HF_USER/bge-m3-legal-euro-${Rn}-gguf" \
    "$DRIVE_GGUF" --repo-type model
echo "GGUF uploaded"

echo ""
echo "=== Done ==="

runpodctl remove pod $RUNPOD_POD_ID
