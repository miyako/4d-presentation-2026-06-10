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
  --exclude "*.DS_Store"
```

## Option 1: Train on Google Colab

### Pro

- Quick tests on small VM are free
- Integration with Google Drive
- Pay-as-you-go or subscription

### Con
- Single GPU, no clusters
- Terminate after several minutes of browser inactivity
- Terminate after `7` to `9` hours of activity (preëmption)

### Example for BGE M3

https://colab.research.google.com/drive/170FXbDOp_V12AuKw81O_QFEUSVa0k_tH?usp=sharing
https://colab.research.google.com/drive/1XAqhA8Eto-S0IvD22pG9YFIra3tupy6n?usp=sharing

#### Dataset Stats

```
Rows              : 11563
Positives per row : min=1  max=15  avg=4.2
Negatives per row : min=1  max=13  avg=3.4
```

#### Batch Stats

```
Effective batch : 4
Group size      : 8
Est. steps      : 8672
```

### Loss & Learning Rate

<img width="500" height="auto" alt="training-loss" src="https://github.com/user-attachments/assets/90a7721a-925a-4b4c-9c11-029286a8b964" />

Ask <img width="12" height="12" alt="claude-logo" src="https://github.com/user-attachments/assets/7f11737c-c2eb-4b6f-a025-a02d12ef998d" /> for advice: https://claude.ai/share/26f496a3-e877-43fb-b8df-e024557d13ae

### Measurements before Training

### Measurements after Training
