#Resume from checkpoint:
#torchrun --nproc_per_node=3 /workspace/train.py r10 true /workspace/bge_legal/r10/lora_adapter/checkpoint-5000 2>&1 | tee /workspace/train.log

#Launch fresh:
#torchrun --nproc_per_node=3 /workspace/train.py r10 false 2>&1 | tee /workspace/train.log
