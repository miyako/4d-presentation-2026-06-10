# Taking AI Kit off the Grid  – How to build your own private semantic search engine

### Wednesday, June 10, 2026, 12:00 noon, CDT `UTC−5:00`

## Part 1: Embeddings

For most of the 2000s, computer search relied on matching exact keywords. Wildcards (the `@` symbol in 4D) can only get you so far; synonyms, semantically similar expressions, or reference by pronouns are completely missed by simple lexical matching.

The first breakthrough was the concept of **embeddings**. Instead of working with raw words, the system breaks words into **tokens** and pin them to a specific coordinate on a multi-dimensional vector space that represents language. The token's coordinate, or an *embedding*, becomes a numerical representation of its meaning. 

If a space with hundreds of dimensions is hard to get your head around, imagine a point with hundreds of spikes stemming from it. On one axis, the word "orange" is connected to "lemon" (both are citrus fruits). On another axis, the same word is connected to "yellow" (both are warm colours). On yet another axis it is connected to "juice", and so on. 

Every token is embedded in relation to every other token. The result is that distance in that high-dimensional space reflects semantic similarity. In practice, this means a search for "car" can return results about "vehicles" or "automobiles".

Early systems such as **Word2Vec** (Google, 2013) or **GloVe** (Stanford, 2014) used **static embeddings**, where every token is assigned a fixed vector regardless of context. The improvement is that a database query can find misspelled words or synonyms. The limitation is that a word like "orange" gets the same embedding whether you're talking about fruit or colour.

The next innovation came with **BERT** (Google, 2018), which uses the innovative **Transformer** architecture to create **contextual embeddings**, where the same words or sub-words are pinned to different coordinates depending on their surrounding context. This makes it possible to search by meaning rather than exact phrasing.

### Key Points

- An embedding is the coordinate of a token on a multi-dimensional representation of language.
- An embedding encodes meaning and distance between embeddings represents semantic similarity. 
- Modern systems assign embeddings in context, which captures nuance better than earlier static systems.



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

||Model|The EMS took the...|He sat by the bank of....|||
|-|-|-:|-:|-:|:-:|
|Alibaba|[`Qwen3-Embedding-0.6B`](https://huggingface.co/Qwen/Qwen3-Embedding-0.6B)|`0.6822297199881`|`0.4671879068266`|Jun 2025|🌐
|Alibaba|[`gte-modernbert-base`](https://huggingface.co/Alibaba-NLP/gte-modernbert-base)|`0.8766167991927`|`0.5955026098661`|Jan 2025|
|BAAI|[`bge-m3`](https://huggingface.co/BAAI/bge-m3)|`0.7620673793062`|`0.5429022159838`|Jan 2024|🌐
|Google|[`embeddinggemma-300m`](https://developers.googleblog.com/en/introducing-embeddinggemma/)|`0.8231258099610`|`0.6005312734492`|Sep 2025|🌐
|IBM|[`granite-embedding-311m-multilingual-r2`](https://huggingface.co/ibm-granite/granite-embedding-311m-multilingual-r2)|`0.8995000155276`|`0.9024163112775`|May 2026|🌐
|IBM|[`granite-embedding-english-r2`](https://huggingface.co/ibm-granite/granite-embedding-english-r2)|`0.9168888742887`|`0.7906757326866`|Aug 2025
|JHU|[`ettin-encoder-400m`](https://huggingface.co/jhu-clsp/ettin-encoder-400m)|`0.9914190574350`|`0.9670910944748`|Jul 2025|🌐
|Microsoft|[`multilingual-e5-base`](https://huggingface.co/intfloat/multilingual-e5-base)|`0.9219811054545`|`0.7896724295248`|Dec 2022|🌐
|Microsoft|[`e5-base-v2`](https://huggingface.co/intfloat/e5-base-v2)|`0.9272583449536`|`0.7394167512544`|Dec 2022
|Nomic|[`nomic-embed-text-v2-moe`](https://huggingface.co/nomic-ai/nomic-embed-text-v2-moe)|`0.6332263233029`|`0.4085057202734`|Feb 2025|🌐
|Nomic|[`nomic-embed-text-v1.5`](https://www.nomic.ai/news/nomic-embed-matryoshka)|`0.8346119269962`|`0.5344995632986`|Feb 2024
|Snowflake|[`snowflake-arctic-embed-l-v2.0`](https://www.snowflake.com/en/blog/engineering/snowflake-arctic-embed-2-multilingual/)|`0.7543962955285`|`0.5548135169332`|Dec 2024|🌐
|Snowflake|[`snowflake-arctic-embed-l`](https://www.snowflake.com/en/blog/engineering/introducing-snowflake-arctic-embed-snowflakes-state-of-the-art-text-embedding-family-of-models/)|`0.8680784582381`|`0.6961994192399`|Apr 2024|
