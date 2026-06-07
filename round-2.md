## Upload dataset to Hugging Face

```sh
cd {dataset}
hf upload {account}/{repo} . \
  --repo-type dataset \
  --exclude "**.DS_Store"
```

e.g.

```
hf upload keisuke-miyako/RUNPOD_API_KEY . \
  --repo-type dataset \
  --exclude "**.DS_Store"
```

```
It seems you are trying to upload a large folder at once. This might take some time and then fail if the folder is too large. For such cases, it is recommended to upload in smaller batches or to use `HfApi().upload_large_folder(...)`/`hf upload-large-folder` instead. For more details, check out https://huggingface.co/docs/huggingface_hub/main/en/guides/upload#upload-a-large-folder.
```


