# How does semantic search engine work

## Text Comparison

Classic database search engines search for documents by basic text comparison. The search engine may implement several modes of string comparison. Think of the 4D command [`Compare strings`](https://developer.4d.com/docs/commands/compare-strings). The comparison can be:

- case insensitive
- diacritic insensitive
- base on character code

Combined with wildcards operators that match any character, the engine casts a wide net to catch as many relevant documents as possible.

## Neural Network Models

Neural Network Models, or machine learning, is the technology at the core of modern artificial intelligence, including large language models. 

An NNM has been trained to pickup strong signals from digital data that are similar to each other in some meaningful way. The objects to compare can be text, image, audio, or video. The comparison even works across different modalities.

Today we will focus on comparing text to some other text.

When a piece of digital information, for example, some text, is mapped to a Neural Network Model, that information is pinned, or embedded, to a specific location on the vast network. That location on the digital network is called an embedding.

The "megascience" [demo](https://huggingface.co/spaces/davanstrien/megascience) visualises how embeddings are located in relation to each other. The actual datapoints are scatted in a multi-dimensional vector space. Notice how topically similar pieces of text are clustered. 

## OpenAI

OpenAI has an API to turn text into embeddings. We can use their services from 4D with 4D AI Kit.

- Create embeddings with OpenAI
- How compare cosine similarity

OpenAI embedding models are powerful, but usage is not free. You also need to send your documents to OpenAI over the internet. Their model is proprietary and not customisable. 

An alternative solution would be to host an open-weight model locally. It will not cost you API credits and you do not need to send sensitive data over the internet. If necessary, you can even fine-tune the model to pick up subtle signals from specific documents. 

## LlaMA.cpp

LlaMA.cpp is the de facto standard for running LLMs locally. It is the core engine that powers the popular Ollama, LM Studio and LocalAI. You can build or install llama.cpp yourself. Or you can just use Dependency Manager.

- Create embeddings with OpenAI
- How compare cosine similarity

## Search 4D Documentation 

I decided to use the documentation as my dataset to showcase semantic search.

You can download the static version of the documentation pages from Github. The main branch is the source code, i.e. markdown files. The `gh-pages` branch contains the static HTML files generated from the markdown files. I've downloaded the static HTML files to my data folder. Points of interest:

- I save the 4D.File object directly to my object field.
- I extract plain text from the HTML files in chunks.
- I convert the text to embeddings in batches and save them to my object field.

## BGE M3

The open weight model I use locally is BGE M3. Look at the download numbers. You can compute cosine similarity online. The model ranks high on the trending list for sentence similarity on Hugging Face. The model was trained in 13 languages. The researchers used text from wikipedia, then asked GPT 3.5 to "please generate one specific and valuable question based on the following text". Using a frontier AI to teach another AI is quite common.

We can deploy the same tactic to provide more training for the model. I used a prompt to generate more training data. I got help from AI to create this prompt. The trick is to ask the AI to deliberately generate queries that clearly match or miss the passage. This saves me from marking the queries as positive or negative manually. 

- Static instructions are given in the system prompt. 
- Dynamic instructions are given in the user prompt.
- Passages are injected using 4D tags.

I created a form to test my query performance. Level 3 is the hard match, so the perfect result is for the red record, the document that corresponds to the query to be the only match. Extra while records are fine, may they are also relevant. 

Level 0 and 1 are negatives, so the result should not contain the red record. if the red record is included it means the model failed to understand that the passage is syntactically similar but topically unrelated. Such misleading examples are called hard negatives. Hard negatives are the key ingredients for fine-tuning an LLM.

I created a method to find hard negatives in my dataset. It took my laptop about 17 hours to mine 30K rows of hard negatives from a combination of 50K queries and 142K passages.

Training that takes multiple weeks on a CPU can finish in an hour on a GPU. 

## LoRA

I use RunPod which is an online service that rents GPU by the minute for model training. 

I training system is called low ranking adaptation, or LoRA. Instead of modifying the entire neural network, a small subset of datapoints, called transformer heads are adjusted. Just light a pair of reading glasses sharpens vision, an adapter changes how the model sees the world.

The python script generates and upload a chart that shows the LoRA training record, measured in learning loss. At first the model misjudges the relation between a query and a hard negative, but quickly adapts. The rest of the training is spent on making small improvements.

LoRA is an iterative process. A fine-tuned model is better at finding harder negatives, which an be used for the next round of training. The challenge is to progressively improve on certain task without becoming worse on other tasks.

## Final Demo

- The prompt was written with help from AI.
- Tool call implements semantic search.
- The web area HTML was also generated by AI.
