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

#### Dataset Stats

```
Rows              : 11563
Positives per row : min=1  max=15  avg=4.2
Negatives per row : min=1  max=13  avg=3.4
```

#### Measurements before Training

|Relevance|Min|Max|Average|
|:-:|-:|-:|-:|
|`3`|`0.22`|`0.80`|`0.52`
|`2`|`0.22`|`0.77`|`0.50`
|`1`|`0.26`|`0.69`|`0.47`
|`0`|`0.21`|`0.63`|`0.40`

#### Round 1 (r11)

https://colab.research.google.com/drive/170FXbDOp_V12AuKw81O_QFEUSVa0k_tH?usp=sharing
https://colab.research.google.com/drive/1XAqhA8Eto-S0IvD22pG9YFIra3tupy6n?usp=sharing

```
learning rate:  : 1e-5
epochs          : 3
batch/device    : 4
gpu             : 1
```

<img width="500" height="auto" alt="training-loss" src="https://github.com/user-attachments/assets/90a7721a-925a-4b4c-9c11-029286a8b964" />

Ask <img width="12" height="12" alt="claude-logo" src="https://github.com/user-attachments/assets/7f11737c-c2eb-4b6f-a025-a02d12ef998d" /> for advice: https://claude.ai/share/26f496a3-e877-43fb-b8df-e024557d13ae

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

#### Round 2 (r12)

https://colab.research.google.com/drive/1pXcGt0nIrgcj976-fY6yb4hvuH2xHyvu?usp=sharing
https://colab.research.google.com/drive/1bDpXaBE2ck4Ajs1xeoD5MMI8M-ZAkS8b?usp=sharing

```
learning rate:  : 8e-6↓
epochs          : 2↓
batch/device    : 4
gpu             : 1
```

<img width="500" height="auto" alt="training-loss" src="https://github.com/user-attachments/assets/2e9d730d-2109-4bf7-b720-1995f7bbb867" />

Ask <img width="12" height="12" alt="claude-logo" src="https://github.com/user-attachments/assets/7f11737c-c2eb-4b6f-a025-a02d12ef998d" /> for advice: https://claude.ai/share/4bb410a2-fdb4-49d7-bcb7-afa54b63da31

|Relevance|Min|Max|Average|
|:-:|-:|-:|-:|
|`3`|`0.01`|`0.75`|`0.46`
|`2`|`0.02`|`0.73`|`0.44`
|`1`|`0.01`|`0.66`|`0.39`
|`0`|`-0.00`|`0.62`|`0.26`

- The overall cosine similarity is slightly less depressed: good
- Otherwise not that different from last round: not good
- Most of the meaningful learning happened in the first ~10% of training: not good
 
> [!WARNING]
> This might be the limit of Google Colab where you can only rent a **single** GPU. You may have to move on to multiple GPUs at this point. You can't increase per-device-batch, or add more transformer layers, or increase gradient accumilation on a Google Colab NVIDIA A100 which has a limited `40` GB memory.

Ask <img width="12" height="12" alt="claude-logo" src="https://github.com/user-attachments/assets/7f11737c-c2eb-4b6f-a025-a02d12ef998d" /> for LoRA primer: https://claude.ai/share/acab7883-7b90-49ad-8bc8-334b43edc333

## Option 2: Train on RunPod

> [!TIP]
> When training is conducted across multiple GPUs (`negatives_cross_device`), each query is compared against `1` random positive and `group size-1` random negatives, plus the passages sitting on other GPUs which act as extra "in-batch negatives". With a large enough dataset, the statistical probability of two nearly identical queries ending up in the exact same global batch is extremely low. 

#### Round 3 (r13)

```
learning rate:  : 5e-6↑
epochs          : 2
batch/device    : 8↑
gpu             : 3↑
group size      : 5
```

<img width="500" height="auto" alt="training-loss" src="https://github.com/user-attachments/assets/98e36ab6-5c5c-4ad7-8086-45c6fee996ed" />

Ask <img width="12" height="12" alt="claude-logo" src="https://github.com/user-attachments/assets/7f11737c-c2eb-4b6f-a025-a02d12ef998d" /> for advice: https://claude.ai/share/4a05d25f-7141-4514-a877-146c5d47b263

|Relevance|Min|Max|Average|
|:-:|-:|-:|-:|
|`3`|`0.12`|`0.80`|`0.51`
|`2`|`0.12`|`0.78`|`0.49`
|`1`|`0.12`|`0.72`|`0.45`
|`0`|`0.05`|`0.70`|`0.31`

- The attention output path is frozen: not good
- Warmup is too long: not good
- The `dense` layer is not trained: not good

## Analysis of Your Fine-Tune Results

### Overall Verdict: **Mixed — promising signal, but imbalanced learning**

The spread doubling (0.12 → 0.24) is a real win, but the gains came almost entirely from **pushing negatives down**, not pulling positives up. That's the core problem.

### What went well ✅

| Observation | Why it's good |
|---|---|
| Spread 0.12 → 0.24 | Model learned to discriminate at all |
| Neg (0) avg: 0.40 → 0.23 | Strong separation from irrelevant docs |
| Neg can now go negative (-0.05) | Model is more "aggressive" / less shy |
| Warmup 5%, cosine scheduler | Solid, standard choices |
| Rank 64 / Alpha 128 | Reasonable LoRA capacity for a large embedding model |

### What went wrong ❌

**The critical issue:** Positives went *down*, not up.

```
Relevance 3:  0.52 avg  →  0.47 avg   ← should be going UP
Relevance 0:  0.40 avg  →  0.23 avg   ← this part worked
```

Also, the **min for relevance 3 collapsed** from 0.22 → 0.02. Some clearly relevant pairs are now being scored near zero — that's a sign of partial catastrophic forgetting or loss imbalance.

→ Lower temperature sharpens the distribution and forces positives higher.

The `dense` layer in BGE-M3 is part of the projection head — fine-tuning it with LoRA can destabilise the embedding geometry. The original model's positive scores dropping is consistent with this.

→ Remove `dense` and only keep `query, key, value`. Possibly `out_proj`).

Alpha=128 / Rank=64 = effective scale of **2.0**. This is on the high end and amplifies gradient updates. Combined with `dense` in scope, it may be overwriting the pre-trained geometry.

→ Set alpha=64 (= rank) for a more conservative 1.0 scale, which is the common default.

32 devices × 2 GPUs × 2 grad accum = **effective batch of 128**, plus group size 7 = ~896 pairs per step. This is large. With hard negatives at this scale, easy negatives dominate and the loss gets "lazy" — it can satisfy itself by pushing negatives down without learning to score positives higher.

→ **Consider mining harder negatives** or reducing group size to 3–5 with only hard negatives.

#### Round 4 (r14)

```
learning rate:  : 5e-6
epochs          : 3↑
batch/device    : 32↑
gpu             : 2↓
target modules  : dense+
gradient accum. : 2↑
warmup          : 0.05↓
rank            : 64↑
alpha           : 128↑
lr scheduler    : linear→cosine
group size      : 7↑
```

<img width="500" height="auto" alt="training-loss" src="https://github.com/user-attachments/assets/50f3646f-db61-4880-84e4-c93c88172ba4" />

Ask <img width="12" height="12" alt="claude-logo" src="https://github.com/user-attachments/assets/7f11737c-c2eb-4b6f-a025-a02d12ef998d" /> for advice: https://claude.ai/share/b5cc4907-a988-4ba6-8027-68ecce2a2ae6

|Relevance|Min|Max|Average|
|:-:|-:|-:|-:|
|`3`|`0.02`|`0.79`|`0.47`
|`2`|`0.02`|`0.77`|`0.45`
|`1`|`0.04`|`0.72`|`0.41`
|`0`|`-0.05`|`0.69`|`0.23`

- Smoothing learning curve: good
- The learning plateau'd: not good
- Thelearning rate is probably too low: not good

#### Round 5 (r15)

```
learning rate:  : 3e-5↑
epochs          : 3
batch/device    : 32
gpu             : 4↑
target modules  : query, key, value, dense
gradient accum. : 1↓
warmup          : 0.05
rank            : 64
alpha           : 128
lr scheduler    : cosine
group size      : 7
max grad. norm. : 1.0+
```

<img width="500" height="auto" alt="training-loss" src="https://github.com/user-attachments/assets/434eb039-b1f7-4501-bd38-1f76d536ba53" />

#### Round 6 (r16)

```
learning rate:  : 5e-6↓
epochs          : 5↑
batch/device    : 32
gpu             : 4
target modules  : query, key, value
gradient accum. : 1
warmup          : 0.05
rank            : 64
alpha           : 64↓
lr scheduler    : cosine
group size      : 5↓
max grad. norm. : 1.0
```
