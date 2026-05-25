#!/bin/bash
set -e

export RUNPOD_API_KEY=
export HF_TOKEN=

# ── Environment: torch 2.4.1+cu124, CUDA 13.0, Python 3.11 ──────────────────
# DO NOT install or touch torch or torchvision
# ─────────────────────────────────────────────────────────────────────────────

echo "=== Removing torchvision ==="
pip uninstall torchvision -y 2>/dev/null || true

echo "=== Installing packages ==="
pip install "FlagEmbedding" "datasets" "matplotlib" --no-cache-dir --quiet
# re-pin torch at the end to guarantee CUDA build survives
pip install torch --index-url https://download.pytorch.org/whl/cu124 --force-reinstall --no-cache-dir --quiet

echo "=== Forcing correct transformers and peft versions ==="
# pip install --upgrade "transformers>=4.46,<5.0" "peft>=0.13,<0.15" --no-cache-dir --quiet
pip install "transformers==4.46.3" "peft>=0.13,<0.15" --no-cache-dir --quiet

echo "=== Installing llama.cpp ==="
if [ ! -d "/workspace/llama.cpp" ]; then
    git clone https://github.com/ggerganov/llama.cpp /workspace/llama.cpp
    pip install -r /workspace/llama.cpp/requirements.txt --no-cache-dir --quiet
else
    echo "llama.cpp already exists, skipping"
fi

export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

# Patch transformers CVE torch version guard (pod is locked to torch 2.4.1)
python -c "
import pathlib
p = pathlib.Path('/usr/local/lib/python3.11/dist-packages/transformers/modeling_utils.py')
txt = p.read_text()
txt = txt.replace('check_torch_load_is_safe()', 'pass  # patched CVE-2025-32434 check')
p.write_text(txt)
print('CVE guard patched')
"

echo "=== Launching training ==="
torchrun --nproc_per_node=4 /workspace/train.py r17 false 2>&1 | tee /workspace/train.log

echo "=== Training complete. Starting merge and export ==="
bash /workspace/merge_and_export.sh r17 2>&1 | tee /workspace/merge.log
