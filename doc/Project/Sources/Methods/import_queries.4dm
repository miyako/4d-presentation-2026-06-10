//%attributes = {}
//TRUNCATE TABLE([Search])
//SET DATABASE PARAMETER([Search]; Table sequence number; 0)

var $files : Collection
$files:=[File:C1566("/DATA/prompts/v2/Anthropic-claude-sonnet-4-6-batch-response.jsonl")]
var $file : 4D:C1709.File
For each ($file; $files)
	var $jsonl : Collection
	$jsonl:=Split string:C1554($file.getText("utf-8"; Document with LF:K24:22); "\n")
	var $line : Text
	For each ($line; $jsonl)
		var $json : Object
		$json:=Try(JSON Parse:C1218($line; Is object:K8:27))
		If ($json=Null:C1517)
			continue
		End if 
		var $id : Text
		$id:=Delete string:C232($json.custom_id; 1; Position:C15("-"; $json.custom_id))
		var $passage : cs:C1710.PassageEntity
		$passage:=ds:C1482.Passage.get(Num:C11($id))
		If ($passage=Null:C1517)
			continue
		End if 
		ARRAY LONGINT:C221($pos; 0)
		ARRAY LONGINT:C221($len; 0)
		var $type; $content : Text
		Case of 
			: ($json.response#Null:C1517)
				$type:="OpenAI"
				$content:=$json.response.body.choices.first().message.content
			: ($json.result#Null:C1517)
				$type:="Anthropic"
				$content:=$json.result.message.content.first().text
			Else 
				$content:=""
		End case 
		If ($content="")
			continue
		End if 
		If (Match regex:C1019("```json(?msi)(.+)```$"; $content; 1; $pos; $len))
			$content:=Substring:C12($content; $pos{1}; $len{1})
		End if 
		var $results : Collection
		$results:=Try(JSON Parse:C1218($content; Is collection:K8:32))
		If ($results=Null:C1517)
			continue
		End if 
		var $client : cs:C1710.AIKit.OpenAI
		$client:=cs:C1710.AIKit.OpenAI.new({baseURL: "http://127.0.0.1:"+String:C10(Storage:C1525.port.embeddings)+"/v1"})
		var $model : Text
		$model:="bge-m3"
		var $params : cs:C1710.AIKit.OpenAIEmbeddingsParameters
		$params:=cs:C1710.AIKit.OpenAIEmbeddingsParameters.new()
		var $batch : Object
		$batch:=$client.embeddings.create($results.extract("text"); $model; $params)
		If ($batch.success)
			var $embeddings : Collection
			$embeddings:=$batch.embeddings
			var $result : Object
			var $search : cs:C1710.SearchEntity
			For each ($result; $results)
				$search:=ds:C1482.Search.new()
				$search.language:=$result.language
				$search.relevance:=$result.relevance
				$search.text:=$result.text
				$search.hash:=Generate digest:C1147($result.text; SHA1 digest:K66:2)
				$search.passage:=$passage
				$search.meta:={model: "claude-sonnet-4-6"; provider: "Anthropic"}
				$search.embeddings:=$embeddings.shift().embedding
				$search.save()
			End for each 
		End if 
	End for each 
End for each 
