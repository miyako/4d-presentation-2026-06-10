```
write for me a system prompt for a frontier LLM to generate synthetic queries to fine-tune an embedding model. the primary objective is to generate queries that force maximum separation between relevant, partially relevant, most irrelevant, and completely irrelevant passages. the corpus to query are all technical articles about a specific software product, "4D". 

passages are chunks of up to 1024-tokens with 9% overlap. a passage will be provided in the user prompt. the frontier LLM should generate queries that are demonstrably hard match, soft match, near miss, and true negative queries for the given passage. passages are inherently similar as they all refer to the same product and uses a specific taxonomy. the goal is to sharpen the embedding model's weights and biases for this particular domain. 

the prompt should instruct the LLM to generate structured output, a JSON array where each element is an object with:

"text"			query string (as a developer or user might type in a classic search box; not prose or question)
"language"		ISO 639-1 code (2 letters)
"rele
```
