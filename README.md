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

## LoRA

### LoRA Parameters

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

|Relevance|Min|Max|Average|
|:-:|-:|-:|-:|
|`3`|`0.22`|`0.80`|`0.52`
|`2`|`0.22`|`0.77`|`0.50`
|`1`|`0.26`|`0.69`|`0.47`
|`0`|`0.21`|`0.63`|`0.40`

### Measurements after Training

|Relevance|Min|Max|Average|
|:-:|-:|-:|-:|
|`3`|`-0.02`|`0.74`|`0.45`
|`2`|`-0.01`|`0.73`|`0.43`
|`1`|`-0.01`|`0.66`|`0.38`
|`0`|`-0.04`|`0.61`|`0.25`

- The "spread" widened from `0.12` to `0.20`: presumably good
- The hierarchy is instact: demonstratively good
- The overall cosine similarity is depressed: potentially bad
- Possible **overfitting**: not good

### Example for BGE M3 (2nd round)

https://colab.research.google.com/drive/1pXcGt0nIrgcj976-fY6yb4hvuH2xHyvu?usp=sharing
https://colab.research.google.com/drive/1bDpXaBE2ck4Ajs1xeoD5MMI8M-ZAkS8b?usp=sharing

<img width="500" height="auto" alt="training-loss" src="https://github.com/user-attachments/assets/2e9d730d-2109-4bf7-b720-1995f7bbb867" />

Ask <img width="12" height="12" alt="claude-logo" src="https://github.com/user-attachments/assets/7f11737c-c2eb-4b6f-a025-a02d12ef998d" /> for advice: https://claude.ai/share/4bb410a2-fdb4-49d7-bcb7-afa54b63da31

> This is the limit of Google Colab which only affords a single GPU. You may have to move on to GPU clusters.
