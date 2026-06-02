//%attributes = {}
var $client : cs:C1710.AIKit.OpenAI
$client:=cs:C1710.AIKit.OpenAI.new({baseURL: "http://127.0.0.1:"+String:C10(Storage:C1525.port.embeddings)+"/v1"})

var $query : Text
$query:="create a new entry filter in toolbox"

var $params : cs:C1710.AIKit.OpenAIEmbeddingsParameters
$params:=cs:C1710.AIKit.OpenAIEmbeddingsParameters.new()
var $batch : Object
$batch:=$client.embeddings.create($query)

If ($batch.success)
	var $embedding : 4D:C1709.Vector
	$embedding:=$batch.embedding.embedding
	var $comparison:={vector: $embedding; metric: mk cosine:K95:1; threshold: 0.6}
	var $documents : cs:C1710.DocumentSelection
	$documents:=ds:C1482.Document.query("passages.embeddings > :1"; $comparison)
	var $document : cs:C1710.DocumentEntity
	For each ($document; $documents.slice(0; 3))
		OPEN URL:C673($document.file.platformPath)
	End for each 
End if 