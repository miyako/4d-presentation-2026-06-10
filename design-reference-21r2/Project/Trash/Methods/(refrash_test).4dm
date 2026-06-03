//%attributes = {}
var $client : cs:C1710.AIKit.OpenAI
$client:=cs:C1710.AIKit.OpenAI.new({baseURL: "http://127.0.0.1:"+String:C10(Storage:C1525.port.embeddings)+"/v1"})
var $model : Text
$model:="bge-m3"

var $document : cs:C1710.DocumentEntity
For each ($document; ds:C1482.Document.all())
	
	var $file : 4D:C1709.File
	$file:=$document.file
	
	If (Not:C34($file.exists))
		continue
	End if 
	
	If ($document.passages.length=0)
		continue
	End if 
	
	var $task : Object
	$task:={file: $file; \
		text_as_tokens: False:C215; \
		tokens_length: 509; \
		overlap_ratio: 0.9; \
		unique_values_only: False:C215; \
		pooling_mode: Extract Pooling Mode CLS}
	var $extracted : Object
	$extracted:=Extract(Extract Document HTML; Extract Output Collection; $task)
	If ($extracted.success)
		Case of 
			: ($extracted.input.includes("@404 - Not Found"))
				continue
			: ($extracted.input.includes("@developer.4d.com/docs@"))
				continue
			Else 
				var $params : cs:C1710.AIKit.OpenAIEmbeddingsParameters
				$params:=cs:C1710.AIKit.OpenAIEmbeddingsParameters.new()
				var $batch : Object
				$batch:=$client.embeddings.create($extracted.input; $model; $params)
				If ($batch.success)
					var $embeddings : Collection
					$embeddings:=$batch.embeddings
					var $text : Text
					var $passage : cs:C1710.PassageEntity
					For each ($passage; $document.passages)
						$text:=$extracted.input.shift()
						$passage.text:=$text
						$passage.hash:=Generate digest:C1147($text; SHA1 digest:K66:2)
						$passage.embeddings:=$embeddings.shift().embedding
						$passage.save()
					End for each 
				End if 
		End case 
	End if 
End for each 