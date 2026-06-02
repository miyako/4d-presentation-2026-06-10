//%attributes = {}
#DECLARE($chatCompletionsResult : cs:C1710.AIKit.OpenAIChatCompletionsResult)

If (Count parameters:C259=0)
	
	CALL WORKER:C1389(Current method name:C684; Current method name:C684; {})
	
Else 
	
	If (This:C1470=Null:C1517)
		
		var $agent : cs:C1710._AgentRemote
		$agent:=cs:C1710._AgentRemote.new("Claude"; "claude-sonnet-4-6")
		
		var $folder : 4D:C1709.Folder
		$folder:=Folder:C1567("/DATA/prompts/queries")
		var $systemPrompt; $userPrompt; $userPromptTemplate : Text
		$systemPrompt:=$folder.file("system.txt").getText()
		$userPromptTemplate:=$folder.file("user.txt").getText()
		
		var $passage : cs:C1710.PassageEntity
		$passage:=ds:C1482.Passage.query("searches != null").first()
		
		If ($passage=Null:C1517)
			TRACE:C157
			return 
		End if 
		
		var $name; $language; $text; $version : Text
		$name:=$passage.document.file.name
		ARRAY LONGINT:C221($pos; 0)
		ARRAY LONGINT:C221($len; 0)
		If (Match regex:C1019("\\.([a-z]{2})$"; $name; 1; $pos; $len))
			$language:=Substring:C12($name; $pos{1}; $len{1})
		Else 
			$language:="en"
		End if 
		$text:=$passage.text
		$version:="21R2"
		PROCESS 4D TAGS:C816($userPromptTemplate; $userPrompt; {text: $text; language: $language; version: $version})
		
		var $messages:=[]
		
		$messages.push({role: "system"; content: $systemPrompt})
		$messages.push({role: "user"; content: $userPrompt})
		
		$agent.passage:=$passage.getKey()
		$agent.startConversation($messages; Formula from string:C1601(Current method name:C684))
		
	Else 
		
		var $results : Collection
		$results:=Try(JSON Parse:C1218(This:C1470.ChatResult; Is collection:K8:32))
		
		If ($results#Null:C1517)
			$passage:=ds:C1482.Passage.get(This:C1470.passage)
			Case of 
				: ($results.length=0)
					//page with no content 
					$passage.drop()
				Else 
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
						var $search : cs:C1710.SearchEntity
						var $result : Object
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
					
			End case 
			
		End if 
	End if 
End if 