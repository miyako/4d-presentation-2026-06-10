//%attributes = {"invisible":true}
/*
E5 models expect the "passage:" prefix
*/

var $client : cs:C1710.AIKit.OpenAI
$client:=cs:C1710.AIKit.OpenAI.new({baseURL: "http://127.0.0.1:8888/v1"})

var $model : Text
$model:="e5-base-v2"  //English
$model:="multilingual-e5-base"

var $inputs : Collection
$inputs:=[]

$inputs[0]:="passage: The EMS took the male patient with chest pains to the local hospital."
$inputs[1]:="passage: A man with cardiac symptoms was carried by ambulance to the nearest ER."

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

$inputs[0]:="passage: He sat by the bank of the river, resting under the branch of an old oak tree."
$inputs[1]:="passage: Ms. River withdrew cash from the bank before the branch closed for the day."

$batch:=$client.embeddings.create($inputs; $model)

If ($batch.success)
	$embeddings:=$batch.embeddings
	$cosineSimilarity:=$embeddings[0].embedding.cosineSimilarity($embeddings[1].embedding)
End if 