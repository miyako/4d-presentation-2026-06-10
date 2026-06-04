## Upload dataset to Hugging Face

```sh
cd {dataset}
hf upload {account}/{repo} . \
  --repo-type dataset \
  --exclude "**.DS_Store"
```
