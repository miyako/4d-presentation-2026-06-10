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
	//llama-server does not support "dimensions"
	$embedding:=4D:C1709.Vector.new(($batch.embedding.embedding.toCollection().slice(0; 512)))
	var $comparison:={vector: $embedding; metric: mk cosine:K95:1; threshold: 0.6}
	var $documents : cs:C1710.DocumentSelection
	$documents:=ds:C1482.Document.query("meta.version == :1 and passages.embeddings512 > :2"; "21-R2"; $comparison)
	var $document : cs:C1710.DocumentEntity
	For each ($document; $documents)
		OPEN URL:C673($document.file.platformPath)  //3156,15092
	End for each 
End if 