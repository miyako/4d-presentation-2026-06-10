# Taking AI Kit off the Grid  – How to build your own private semantic search engine

### Wednesday, June 10, 2026, 12:00 noon, CDT `UTC−5:00`


> [!TIP]
> `hf upload-large-folder` does not support `.gitignore`

```
hf upload-large-folder keisuke-miyako/legal-euro-2026-0524 . \
  --repo-type=dataset \
  --num-workers=10 \
  --exclude "llm/*" \
  --exclude ".DS_Store"
```
