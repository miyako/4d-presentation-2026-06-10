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

> [!WARNING]
> This might be the limit of Google Colab where you can only rent a **single** GPU. You may have to move on to multiple GPUs at this point. You can't increase per-device-batch, or add more transformer layers, or increase gradient accumilation on a Google Colab NVIDIA A100 which has a limited `40` GB memory.

Ask <img width="12" height="12" alt="claude-logo" src="https://github.com/user-attachments/assets/7f11737c-c2eb-4b6f-a025-a02d12ef998d" /> for LoRA primer: https://claude.ai/share/acab7883-7b90-49ad-8bc8-334b43edc333

## Option 2: Train on RunPod

> [!TIP]
> When training is conducted across multiple GPUs (`negatives_cross_device`), each query is compared against `1` random positive and `group size-1` random negatives, plus the passages sitting on other GPUs which act as extra "in-batch negatives". With a large enough dataset, the statistical probability of two nearly identical queries ending up in the exact same global batch is extremely low. 

> [!NOTE]
> GPU may become unavailable for an extended period of time, depending on the hour of day and region. It would be wise to have a network storage on each side of the Atlantic (Europe and Canada) so that you do not have to wait until the GPUs come online.

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

#### Round 4 (r14)

Add `dense` layer to LoRA

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

Ask <img width="12" height="12" alt="claude-logo" src="https://github.com/user-attachments/assets/7f11737c-c2eb-4b6f-a025-a02d12ef998d" /> for advice: https://claude.ai/share/bc471893-e83a-4969-8c54-5f9cd1dce6cd

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
group size      : 5↓
max grad. norm. : 1.0
```

<img width="500" height="auto" alt="training-loss" src="https://github.com/user-attachments/assets/330531e8-87b8-4b7d-9c74-dc3ab23ea634" />

Ask <img width="12" height="12" alt="claude-logo" src="https://github.com/user-attachments/assets/7f11737c-c2eb-4b6f-a025-a02d12ef998d" /> for advice: https://claude.ai/share/8966219c-ddc0-4dbd-9e4c-7546e578c325

|Relevance|Min|Max|Average|
|:-:|-:|-:|-:|
|`3`|`0.27`|`0.76`|`0.56`
|`2`|`0.15`|`0.77`|`0.50`
|`1`|`0.27`|`0.69`|`0.46`
|`0`|`0.14`|`0.53`|`0.31`

#### Round 8 (r18)

Switch to reranker generated dataset `18794` rows (no more GPT selected rows)

```
learning rate:  : 5e-6
epochs          : 4↑
batch/device    : 32
gpu             : 4
target modules  : query, key, value, dense
gradient accum. : 1
warmup          : 0.05
rank            : 64
alpha           : 64
group size      : 6
```

<img width="500" height="auto" alt="training-loss" src="https://github.com/user-attachments/assets/e4e62b74-20e7-4c24-9606-049c02f00113" />

Ask <img width="12" height="12" alt="claude-logo" src="https://github.com/user-attachments/assets/7f11737c-c2eb-4b6f-a025-a02d12ef998d" /> https://claude.ai/share/51cd7ae2-c0a4-4d9e-8d56-dbe458afb52a

|Relevance|Min|Max|Average|
|:-:|-:|-:|-:|
|`3`|`0.20`|`0.78`|`0.55`
|`2`|`0.07`|`0.78`|`0.47`
|`1`|`0.17`|`0.70`|`0.44`
|`0`|`0.02`|`0.51`|`0.24`
  
#### Round 9 (r19)

```
learning rate:  : 8e-6↑
epochs          : 5↑
batch/device    : 32
gpu             : 4
target modules  : query, key, value, dense
gradient accum. : 1
warmup          : 0.05
rank            : 128↑
alpha           : 128↑
group size      : 6
```

<img width="500" height="auto" alt="training-loss" src="https://github.com/user-attachments/assets/d9e64562-b6ff-4ee5-8e35-2c5697e09c59" />

Ask <img width="12" height="12" alt="claude-logo" src="https://github.com/user-attachments/assets/7f11737c-c2eb-4b6f-a025-a02d12ef998d" /> 
https://claude.ai/share/42192258-5ed4-4234-b1b9-12d753233119

|Relevance|Min|Max|Average|
|:-:|-:|-:|-:|
|`3`|`0.07`|`0.78`|`0.50`
|`2`|`-0.11`|`0.77`|`0.41`
|`1`|`0.05`|`0.71`|`0.37`
|`0`|`-0.12`|`0.45`|`0.12`
  
#### Round 10 (r20)

```
learning rate:  : 5e-6↓
epochs          : 2
batch/device    : 32
gpu             : 4
target modules  : query, key, value, dense
gradient accum. : 1
warmup          : 0.05
rank            : 128
alpha           : 128
group size      : 4
```

<img width="500" height="auto" alt="training-loss" src="https://github.com/user-attachments/assets/519a6d49-8ddc-4390-8356-c9f952ee368d" />


> [!TIP]
> `grad_accum` has the effect of making a single GPU do the job of multiple GPUs simultaneously; for example, `grad_accum=4` means the GPU runs 4 batches and averages the accumulated weights. With 4 GPUs, the work could be done simultaneously. Setting `negatives_cross_device` to `False` means each GPU will work with the batch it has been assigned. It will typically see fewer negatives for each positive. Setting `negatives_cross_device` to `True` means each GPU will also see the negatives assigned to other GPUs. The idea is weigh the position in relation to a diverse set of negatives. The mode is effective when training with a wide variety of data. It may backfire when training with a narrow, domain specific dataset.

#### Round 11 (r21)

Switch to exploded dataset [2026-0526](https://huggingface.co/datasets/keisuke-miyako/legal-euro-2026-0525/settings) 

```
Original rows : 17808
Exploded rows : 84413
Expansion     : 4.74x
```

https://colab.research.google.com/drive/1rGyyUfh_Fu9rzlhtThv0Eb51ySjrVsb2?usp=sharing

```
neg. device     : False
gradient accum. : 1
epochs          : 3↓
temperature     : 0.02↓
rank            : 128
alpha           : 128
group size      : 4
```
