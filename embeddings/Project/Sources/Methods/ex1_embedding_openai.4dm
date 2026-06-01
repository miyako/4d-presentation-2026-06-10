//%attributes = {"invisible":true}
var $LLM : cs:C1710.RemoteLLM
$LLM:=cs:C1710.RemoteLLM.new("OpenAI")

var $client : cs:C1710.AIKit.OpenAI
$client:=cs:C1710.AIKit.OpenAI.new({baseURL: $LLM.baseURL; apiKey: $LLM.apiKey})

var $model : Text
$model:="text-embedding-3-small"

var $inputs : Collection
$inputs:=[]

$inputs[0]:="The EMS took the male patient with chest pains to the local hospital."
$inputs[1]:="A man with cardiac symptoms was carried by ambulance to the nearest ER."

var $embeddings : Collection
var $cosineSimilarity : Real

var $params : cs:C1710.AIKit.OpenAIEmbeddingsParameters
$params:=cs:C1710.AIKit.OpenAIEmbeddingsParameters.new({dimensions: 256})
$batch:=$client.embeddings.create($inputs; $model; $params)

If ($batch.success)
	$embeddings:=$batch.embeddings
	$cosineSimilarity:=$embeddings[0].embedding.cosineSimilarity($embeddings[1].embedding)
	//0.6704454409872 (1536)
	//0.6736194321964 (1024)
	//0.6851947548874 (768)
	//0.6795581069821 (512)
	//0.6687100547955 (384)
	//0.6985858836023 (256)
End if 

$inputs[0]:="He sat by the bank of the river, resting under the branch of an old oak tree."
$inputs[1]:="Ms. River withdrew cash from the bank before the branch closed for the day."

$batch:=$client.embeddings.create($inputs; $model)

If ($batch.success)
	$embeddings:=$batch.embeddings
	$cosineSimilarity:=$embeddings[0].embedding.cosineSimilarity($embeddings[1].embedding)
	//0.3636059621919
End if 