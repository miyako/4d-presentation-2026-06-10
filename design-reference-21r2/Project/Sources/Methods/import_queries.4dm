//%attributes = {}
$files:=Folder:C1567("/DATA/queries").files().query("extension == :1"; ".json")
For each ($file; $files)
	$jsonl:=Split string:C1554($file.getText("utf-8"; Document with LF:K24:22); "\n")
	For each ($line; $jsonl)
		$json:=Try(JSON Parse:C1218($line; Is object:K8:27))
		If ($json=Null:C1517)
			continue
		End if 
		$id:=Delete string:C232($json.custom_id; 1; Position:C15("-"; $json.custom_id))
		$passage:=ds:C1482.Passage.get(Num:C11($id))
		If ($json.result.message=Null:C1517)
			continue
		End if 
		$content:=$json.result.message.content.first().text
		ARRAY LONGINT:C221($pos; 0)
		ARRAY LONGINT:C221($len; 0)
		If (Match regex:C1019("^```json(?msi)(.+)```$"; $content; 1; $pos; $len))
			$content:=Substring:C12($content; $pos{1}; $len{1})
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
			$batch:=$client.embeddings.create($results.extract("text"); $model; $params)
			If ($batch.success)
				$embeddings:=$batch.embeddings
				var $search : cs:C1710.SearchEntity
				For each ($result; $results)
					$search:=ds:C1482.Search.new()
					$search.language:=$result.language
					$search.relevance:=$result.relevance
					$search.text:=$result.text
					$search.hash:=Generate digest:C1147($result.text; SHA1 digest:K66:2)
					$search.passage:=$passage
					$search.embeddings:=$embeddings.shift().embedding
					$search.save()
				End for each 
			End if 
		End if 
	End for each 
End for each 
