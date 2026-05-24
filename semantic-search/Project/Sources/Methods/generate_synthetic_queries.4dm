//%attributes = {"invisible":true,"preemptive":"capable"}
#DECLARE($chatCompletionsResult : cs:C1710.AIKit.OpenAIChatCompletionsResult)

var $id:="queries"

If (Count parameters:C259=0)
	
	CALL WORKER:C1389(Current method name:C684; Current method name:C684; {})
	
Else 
	
	If (This:C1470=Null:C1517)
		
		var $agent : cs:C1710._AgentRemoteQueryTexts
		//$agent:=cs._AgentRemoteQueryTexts.new("Azure_xAI"; "Kimi-K2.6-1")
		//$agent:=cs._AgentRemoteQueryTexts.new("Azure_xAI"; "grok-4-20-reasoning")
		$agent:=cs:C1710._AgentRemoteQueryTexts.new("Azure_xAI"; "gpt-5.4-1")
		
		var $folder : 4D:C1709.Folder
		$folder:=Folder:C1567(fk data folder:K87:12).folder("prompts/"+$id+"/")
		
		var $systemPrompt; $userPrompt : Text
		$systemPrompt:=$folder.file("system.txt").getText()
		$userPrompt:=$folder.file("user.txt").getText()
		
		$passages:=ds:C1482.Passage.query("queried == null")
		
		If ($passages.length=0)
			TRACE:C157
			return 
		End if 
		
		$passage:=$passages.at(Random:C100%$passages.length)
		
		$name:=$passage.document.file.name
		$type:=Split string:C1554($name; "-").first()
		
		$json:={\
			passage: $passage.text; \
			type: $type}
		
		$userPrompt:=Replace string:C233($userPrompt; "{TYPE}"; $json.type; *)
		$LANGUAGES:=["de"; "de"; "de"; "de"; "de"; "de"; "fr"; "fr"; "fr"; "en"]
		$choice:={}
		$choice.random:=Formula:C1597($1[Random:C100%$1.length])
		$LANGUAGE:=$choice.random($LANGUAGES)
		$userPrompt:=Replace string:C233($userPrompt; "{LANGUAGE}"; $LANGUAGE; *)
		$userPrompt:=Replace string:C233($userPrompt; "{PASSAGE}"; $json.passage; *)
		
		var $messages:=[]
		
		$messages.push({role: "system"; content: $systemPrompt})
		$messages.push({role: "user"; content: $userPrompt})
		
		$agent.json:=$json
		$agent.ID:=$passage.getKey()
		$agent.api:=Current method name:C684
		$agent.startConversation($messages; Formula from string:C1601(Current method name:C684))
		
	Else 
		
		var $result : Object
		$result:=Try(JSON Parse:C1218(This:C1470.ChatResult; Is object:K8:27))
		
		If ($result#Null:C1517)
			
			$passage:=ds:C1482.Passage.get(This:C1470.ID)
			$done:=Bool:C1537($passage.queried)
			$passage.queried:=True:C214
			$passage.save()
			
			If (Not:C34($done))
				var $embeddings : cs:C1710.Embeddings
				$embeddings:=cs:C1710.Embeddings.me
				var $texts : Object
				For each ($texts; $result.texts)
					var $query : cs:C1710.QueryEntity
					$query:=ds:C1482.Query.new()
					$query.embedding:=$embeddings.getOne($texts.text)
					$query.text:=$texts.text
					$query.hash:=Generate digest:C1147($query.text; SHA1 digest:K66:2)
					$query.save()
					var $score : cs:C1710.ScoreEntity
					$score:=ds:C1482.Score.new()
					$score._query:=$query
					$score.passage:=$passage
					$score.relevance:=$texts.relevance
					$score.language:=$texts.language
					$score.similarity:=$query.embedding.cosineSimilarity($passage.embedding)
					$score.save()
				End for each 
			End if 
		Else 
			
			If (This:C1470.ChatResult=("The response was filtered due to the prompt triggering Azure OpenAI's content management policy. Please modify your prompt and retry. To learn more about our content filtering policies please read our documentation: https://go.microsoft.com/fwlink/?li"+"nkid=2198766"))
				$passage:=ds:C1482.Passage.get(This:C1470.ID)
				$passage.queried:=True:C214
				$passage.save()
			End if 
		End if 
		
		EXECUTE METHOD:C1007(Current method name:C684)
		
	End if 
	
End if 