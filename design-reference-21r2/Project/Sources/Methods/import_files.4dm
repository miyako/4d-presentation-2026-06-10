//%attributes = {"invisible":true}
/*

html
↓↓↓
txt
↓↓↓
4D.Vector

*/

var $client : cs:C1710.AIKit.OpenAI
$client:=cs:C1710.AIKit.OpenAI.new({baseURL: "http://127.0.0.1:"+String:C10(Storage:C1525.port.embeddings)+"/v1"})
var $model : Text
$model:="bge-m3"

var $files : Collection
$files:=Folder:C1567("/DATA/doc.4d.com/4Dv21R2/").files(fk recursive:K87:7 | fk ignore invisible:K87:22).query("extension == :1"; ".html")

var $file : 4D:C1709.File
For each ($file; $files)
	var $task : Object
	$task:={file: $file; \
		text_as_tokens: False:C215; \
		tokens_length: 509; \
		overlap_ratio: 0.09; \
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
				var $document : cs:C1710.DocumentEntity
				$document:=ds:C1482.Document.new()
				$document.file:=$file
				ARRAY LONGINT:C221($pos; 0)
				ARRAY LONGINT:C221($len; 0)
				var $name : Text
				$name:=$document.file.name
				If (Match regex:C1019("\\.([a-z]{2})"; $name; 1; $pos; $len))
					$language:=Substring:C12($name; $pos{1}; $len{1})
				Else 
					$language:="en"
				End if 
				$document.meta:={version: "21"; language: $language}
				$document.save()
				var $embeddings : Collection
				var $cosineSimilarity : Real
				var $params : cs:C1710.AIKit.OpenAIEmbeddingsParameters
				$params:=cs:C1710.AIKit.OpenAIEmbeddingsParameters.new()
				var $batch : Object
				$batch:=$client.embeddings.create($extracted.input; $model; $params)
				If ($batch.success)
					$embeddings:=$batch.embeddings
					var $text : Text
					For each ($text; $extracted.input)
						var $passage : cs:C1710.PassageEntity
						$passage:=ds:C1482.Passage.new()
						$passage.document:=$document
						$passage.text:=$text
						$passage.hash:=Generate digest:C1147($text; SHA1 digest:K66:2)
						$passage.embeddings:=$embeddings.shift().embedding
						$passage.save()
					End for each 
				End if 
		End case 
	End if 
End for each 
