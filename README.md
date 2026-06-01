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
|Google|`embeddinggemma-300m`|`0.823125809961`|`0.6005312734492`|
|BAAI|`bge-m3`|`0.7620673793062`|`0.5429022159838`|
|IBM|`granite-embedding-311m-multilingual-r2`|`0.8995000155276`|`0.9024163112775`|
|JHU|`ettin-encoder-400m`|`0.991419057435`|`0.9670910944748`
