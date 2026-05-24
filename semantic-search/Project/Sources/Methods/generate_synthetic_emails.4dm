//%attributes = {"invisible":true,"preemptive":"capable"}
#DECLARE($chatCompletionsResult : cs:C1710.AIKit.OpenAIChatCompletionsResult)

var $id:="emails"

var $target_folder : 4D:C1709.Folder
$target_folder:=Folder:C1567(fk data folder:K87:12).folder("datasets").folder($id)
$target_folder.create()

If (Count parameters:C259=0)
	
	CALL WORKER:C1389(Current method name:C684; Current method name:C684; {})
	
Else 
	
	If (This:C1470=Null:C1517)
		
		var $agent : cs:C1710._AgentRemoteTexts
		//$agent:=cs._AgentRemoteTexts.new("Azure_xAI"; "Kimi-K2.6-1")
		//$agent:=cs._AgentRemoteTexts.new("Azure_xAI"; "gpt-5.4-1")
		$agent:=cs:C1710._AgentRemoteTexts.new("Azure_xAI"; "grok-4-20-reasoning")
		
		If ($target_folder.files().query("extension == :1"; ".txt").length>5000)
			TRACE:C157
			return 
		End if 
		
		var $folder : 4D:C1709.Folder
		$folder:=Folder:C1567(fk data folder:K87:12).folder("prompts/"+$id+"/")
		
		var $systemPrompt; $userPrompt : Text
		$systemPrompt:=$folder.file("system.txt").getText()
		$userPrompt:=$folder.file("user.txt").getText()
		
		$choice:={}
		$choice.random:=Formula:C1597($1[Random:C100%$1.length])
		
		var $cases : Collection
		$cases:=Folder:C1567("/DATA/datasets/cases").files(fk ignore invisible:K87:22)
		
		var $PASSAGE : Text
		$PASSAGE:=$cases[Random:C100%$cases.length].getText()
		$userPrompt:=Replace string:C233($userPrompt; "{PASSAGE}"; $PASSAGE; *)
		
		$LANGUAGES:=["de"; "de"; "de"; "de"; "de"; "de"; "de"; "de"; "fr"; "fr"; "en"]
		$LANGUAGE:=$choice.random($LANGUAGES)
		
		$userPrompt:=Replace string:C233($userPrompt; "{LANGUAGE}"; $LANGUAGE; *)
		
		var $messages:=[]
		
		$messages.push({role: "system"; content: $systemPrompt})
		$messages.push({role: "user"; content: $userPrompt})
		
		$agent.task:=$id
		$agent.api:=Current method name:C684
		$agent.startConversation($messages; Formula from string:C1601(Current method name:C684))
		
	Else 
		
		var $result : Object
		$result:=Try(JSON Parse:C1218(This:C1470.ChatResult; Is object:K8:27))
		
		var $results : Collection
		If ($result=Null:C1517)
			$results:=Try(JSON Parse:C1218(This:C1470.ChatResult; Is collection:K8:32))
		Else 
			$results:=[$result]
		End if 
		
		If ($results#Null:C1517)
			For each ($result; $results)
				For each ($texts; $result.texts)
					var $i:=1
					var $fileName : Text
					$fileName:=String:C10($i; "000000")
					While ($target_folder.file("email-"+$texts.language+"-"+$fileName+".txt").exists)
						$i+=1
						$fileName:=String:C10($i; "000000")
					End while 
					$target_folder.file("email-"+$texts.language+"-"+$fileName+".txt").setText($texts.text)
				End for each 
			End for each 
		End if 
		
		//DELAY PROCESS(Current process; 60*30)
		
		EXECUTE METHOD:C1007(Current method name:C684)
		
	End if 
	
End if 