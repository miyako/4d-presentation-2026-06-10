//%attributes = {}
var $client : cs:C1710.AIKit.OpenAI
$client:=cs:C1710.AIKit.OpenAI.new({baseURL: "http://127.0.0.1:"+String:C10(Storage:C1525.port.embeddings)+"/v1"})

$query:="text input <?[TableName]FieldName>"
$query:="list box create hierarchy context menu columns"

var $params : cs:C1710.AIKit.OpenAIEmbeddingsParameters
$params:=cs:C1710.AIKit.OpenAIEmbeddingsParameters.new()
$batch:=$client.embeddings.create($query)

If ($batch.success)
	$embedding:=$batch.embedding.embedding
	var $comparison:={vector: $embedding; metric: mk cosine:K95:1; threshold: 0.6}
	$documents:=ds:C1482.Document.query("passages.embeddings > :1"; $comparison)
	For each ($document; $documents.slice(0; 3))
		OPEN URL:C673($document.file.platformPath)
	End for each 
End if 