# Taking AI Kit off the Grid  – How to build your own private semantic search engine

### Wednesday, June 10, 2026, 12:00 noon, CDT `UTC−5:00`

## embeddings project

Test cosine similarity (remote)

||Model|The EMS took the...|He sat by the bank of....||
|-|-|-:|-:|-:
|Cohere|[`embed-v4.0`](https://cohere.com/blog/embed-4)|`0.5680866656986`|`0.3490104785412`|Apr 2025
|Google|[`gemini-embedding-001`](https://developers.googleblog.com/gemini-embedding-available-gemini-api/)|`0.7856997896712`|`0.6591593431416`|Jul 2025
|Jina|[`jina-embeddings-v5-text-small`](https://jina.ai/news/jina-embeddings-v5-text-distilling-4b-quality-into-sub-1b-multilingual-embeddings/)|`0.7957916859642`|`0.5331879498877`|Feb 2026
|Mistral|[`mistral-embed`](https://docs.mistral.ai/models/model-cards/mistral-embed-23-12)|`0.8800359207449`|`0.7896794842653`|Dec 2023
|NVIDIA|[`nvidia/nv-embed-v1`](https://docs.api.nvidia.com/nim/reference/nvidia-nv-embed-v1)|`0.6504189071027`|`0.2753398975052`|May 2024
|OpenAI|[`text-embedding-3-small`](https://openai.com/index/new-embedding-models-and-api-updates/)|`0.6704454409872`|`0.3636059621919`|Jan 2024
|Voyage|[`voyage-4`](https://blog.voyageai.com/2026/01/15/voyage-4/)|`0.6653823420156`|`0.4358637816462`|Jan 2026

Test cosine similarity (local)

||Model|The EMS took the...|He sat by the bank of....||
|-|-|-:|-:|-:
|Alibaba|`gte-modernbert-base`|`0.8514893095917`|`0.5572938027504`|
|Alibaba|`Qwen3-Embedding-0.6B`|`0.6822297199881`|`0.4671879068266`|Jun 2025
|BAAI|`bge-m3`|`0.7620673793062`|`0.5429022159838`|Jan 2024
|Google|[`embeddinggemma-300m`](https://developers.googleblog.com/en/introducing-embeddinggemma/)|`0.8231258099610`|`0.6005312734492`|Sep 2025
|IBM|`granite-embedding-311m-multilingual-r2`|`0.8995000155276`|`0.9024163112775`|May 2026
|IBM|`granite-embedding-english-r2`|`0.9168888742887`|`0.7906757326866`|Aug 2025
|JHU|`ettin-encoder-400m`|`0.9914190574350`|`0.9670910944748`|Jul 2025
|Microsoft|`multilingual-e5-base`|`0.9219811054545`|`0.7896724295248`|Dec 2022
|Microsoft|[`e5-base-v2`](https://huggingface.co/intfloat/e5-base-v2)|`0.9272583449536`|`0.7394167512544`|Dec 2022
|Nomic|`nomic-embed-text-v2-moe`|`0.6332263233029`|`0.4085057202734`|Feb 2025
|Nomic|[`nomic-embed-text-v1.5`](https://www.nomic.ai/news/nomic-embed-matryoshka)|`0.8346119269962`|`0.5344995632986`|Feb 2024
|Snowflake|[`snowflake-arctic-embed-l-v2.0`](https://www.snowflake.com/en/blog/engineering/snowflake-arctic-embed-2-multilingual/)|`0.7543962955285`|`0.5548135169332`|Dec 2024
