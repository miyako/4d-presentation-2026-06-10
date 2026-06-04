//%attributes = {"invisible":true}
var $client : cs:C1710.AIKit.OpenAI
$client:=cs:C1710.AIKit.OpenAI.new({baseURL: "http://127.0.0.1:8888/v1"})

var $model : Text
$model:="snowflake-arctic-embed-l-v2.0"
$model:="snowflake-arctic-embed-l"  //English
$model:="gte-modernbert"
$model:="granite-embedding-multilingual-r2"
$model:="granite-embedding-english-r2"  //English
$model:="nomic-embed-text-v1.5"  //English
$model:="nomic-embed-text-v2-moe"
$model:="ettin-encoder"
$model:="bge-m3"
$model:="embeddinggemma"

var $inputs : Collection
$inputs:=[]

$inputs[0]:="The EMS took the male patient with chest pains to the local hospital."
$inputs[1]:="A man with cardiac symptoms was carried by ambulance to the nearest ER."

var $embeddings : Collection
var $cosineSimilarity : Real

var $params : cs:C1710.AIKit.OpenAIEmbeddingsParameters
$params:=cs:C1710.AIKit.OpenAIEmbeddingsParameters.new()
var $batch : Object
$batch:=$client.embeddings.create($inputs; $model; $params)

If ($batch.success)
	$embeddings:=$batch.embeddings
	$cosineSimilarity:=$embeddings[0].embedding.cosineSimilarity($embeddings[1].embedding)
End if 

$inputs[0]:="He sat by the bank of the river, resting under the branch of an old oak tree."
$inputs[1]:="Ms. River withdrew cash from the bank before the branch closed for the day."

$batch:=$client.embeddings.create($inputs; $model)

If ($batch.success)
	$embeddings:=$batch.embeddings
	$cosineSimilarity:=$embeddings[0].embedding.cosineSimilarity($embeddings[1].embedding)
End if 