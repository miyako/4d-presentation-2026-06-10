//%attributes = {"invisible":true,"preemptive":"capable"}
#DECLARE($chatCompletionsResult : cs:C1710.AIKit.OpenAIChatCompletionsResult)
/*
the name of the folder that contains the prompts for this task
*/
var $id:="positives"

If (Count parameters:C259=0)
/*
you can make parallel requests from the same worker
by calling the worker multiple times
*/
	CALL WORKER:C1389(Current method name:C684; Current method name:C684; {})
Else 
/*
this part is executed in a worker
This=Null when making an http request
This#Null when the request received a complete response 
*/
	If (This:C1470=Null:C1517)
/*
you need to cast a powerful, frontier model as judge
a local LLM will struggle to follow instructions
or run out of thinking tokens before a verdict 
*/
		var $agent : cs:C1710._AgentRemoteJudge
		//$agent:=cs._AgentRemoteJudge.new("Local"; "Qwen3.5-9B")
		$agent:=cs:C1710._AgentRemoteJudge.new("OpenAI"; "gpt-5.4-mini")
		
		var $folder : 4D:C1709.Folder
		$folder:=Folder:C1567(fk data folder:K87:12).folder("prompts/"+$id+"/")
		
		var $systemPrompt; $userPrompt : Text
		$systemPrompt:=$folder.file("system.txt").getText()
		$userPrompt:=$folder.file("user.txt").getText()
/*
query+passenge cases are stored here 
file extension .json: pending judge
file extension .txt : verdict made
*/
		var $folders : Collection
		$folders:=Folder:C1567("/DATA/llm").folders()
/*
look deep into subfolders
if none are found, there are no more cases to judge
*/
		var $file : 4D:C1709.File
		For each ($folder; $folders)
			$file:=$folder.files(fk recursive:K87:7).query("extension == :1"; ".json").first()
			If ($file#Null:C1517)
				break
			End if 
		End for each 
		
		If ($file=Null:C1517)
			TRACE:C157
			return 
		End if 
		
		$json:=JSON Parse:C1218($file.getText(); Is object:K8:27)
		$passage:=$json.passage
		$query:=$json.query
		$type:=$json.type
		$language:=$json.language
		$passageID:=$json.passageID
/*
other than the query+passage
any material information that matters to the case 
should be factored in; type of document, language, etc
*/
		$userPrompt:=Replace string:C233($userPrompt; "{TYPE}"; $type; *)
		$userPrompt:=Replace string:C233($userPrompt; "{LANGUAGE}"; $language; *)
		$userPrompt:=Replace string:C233($userPrompt; "{QUERY}"; $query; *)
		$userPrompt:=Replace string:C233($userPrompt; "{PASSAGE}"; $passage; *)
		
		var $messages:=[]
		
		$messages.push({role: "system"; content: $systemPrompt})
		$messages.push({role: "user"; content: $userPrompt})
		
		$agent.file:=$file
		$agent.json:=$json
		$agent.passage:=$passage
		$agent.passageID:=$passageID
		$agent.language:=$language
		$agent.ID:=$json.ID
		$agent.api:=Current method name:C684
		$agent.startConversation($messages; Formula from string:C1601(Current method name:C684))
		
	Else 
		
/*
although we pass a json schema
extraorinary responses such as 
content moderation (refuse to process)
out of credit, model out of order,
may result in an unstructured responsed 
*/
		var $result : Object
		$result:=Try(JSON Parse:C1218(This:C1470.ChatResult; Is object:K8:27))
		
		If ($result#Null:C1517)
/*
record the judges' verdict and reasoning for reference
also change the file extension to mark it as processed
*/
			This:C1470.json.verdict:=$result.relevance
			This:C1470.json.reason:=$result.reason
			This:C1470.file.setText(JSON Stringify:C1217(This:C1470.json))
			This:C1470.file.moveTo(This:C1470.file.parent; This:C1470.file.name+".txt")
			
			If ($result.relevance=3)
				//TODO: avoid duplicates
/*
technically, if 2 requests were sent for the same query+passage
you could create duplicate score entries here
that said, to avoid overspend, you might want to run 1 request at a time 
*/
				var $query : cs:C1710.QueryEntity
				$query:=ds:C1482.Query.get(This:C1470.ID)
				var $passage : cs:C1710.PassageEntity
				$passage:=ds:C1482.Passage.get(This:C1470.passageID)
				var $score : cs:C1710.ScoreEntity
				$score:=ds:C1482.Score.new()
				$score._query:=$query
				$score.passage:=$passage
				$score.relevance:=3
				$score.language:=This:C1470.language
				$score.similarity:=$query.embedding.cosineSimilarity($passage.embedding)
				$score.save()
			End if 
		Else 
/*
mark as processed to avoid repeats
*/
			This:C1470.file.moveTo(This:C1470.file.name+".txt")
		End if 
		
		EXECUTE METHOD:C1007(Current method name:C684)
		
	End if 
	
End if 