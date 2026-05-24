# Taking AI Kit off the Grid  – How to build your own private semantic search engine

### Wednesday, June 10, 2026, 12:00 noon, CDT `UTC−5:00`

## Upload dataset to Hugging Face

Use the official [`hf`](https://huggingface.co/docs/huggingface_hub/guides/cli) CLI.

> [!TIP]
> `hf upload-large-folder` does not support `.gitignore`

```
hf upload-large-folder keisuke-miyako/legal-euro-2026-0524 . \
  --repo-type=dataset \
  --num-workers=10 \
  --exclude "llm/*" \
  --exclude "reranker/*" \
  --exclude ".DS_Store"
```

## Option 1: Train on Google Colab

### Pro

- Quick tests on small VM are free
- Integration with Google Drive
- High-end GPUs available
- Pay-as-you-go or subscription

### Con
- Single GPU, no clusters
- CUDA availability is a lottery
- Termination after several minutes of browser inactivity
- Termination after `7` to `9` hours of activity

### Example for BGE M3

https://colab.research.google.com/drive/170FXbDOp_V12AuKw81O_QFEUSVa0k_tH?usp=sharing
