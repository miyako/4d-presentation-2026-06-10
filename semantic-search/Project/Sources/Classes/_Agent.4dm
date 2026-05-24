property OpenAI : cs:C1710.AIKit.OpenAI
property ChatResult : Text
property model : Text
property preemptive : Boolean
property resultObjectName : Text
property startObjectName : Text
property continueObjectName : Text
property promptObjectName : Text
property messages : Collection
property _onResponse : 4D:C1709.Function
property stream : Boolean
property reasoning_content : Text
property thoughts : Text

Class constructor($baseURL : Text; \
$resultObjectName : Text; \
$startObjectName : Text; \
$continueObjectName : Text; \
$promptObjectName : Text)
	
	ASSERT:C1129($baseURL#"")
	
	This:C1470.resultObjectName:=$resultObjectName
	This:C1470.startObjectName:=$startObjectName
	This:C1470.continueObjectName:=$continueObjectName
	This:C1470.promptObjectName:=$promptObjectName
	This:C1470.stream:=True:C214
	This:C1470.OpenAI:=cs:C1710.AIKit.OpenAI.new({baseURL: $baseURL})
	This:C1470.preemptive:=Process info:C1843(Current process:C322).preemptive
	
Function focusUserPrompt() : cs:C1710._Agent
	
	GOTO OBJECT:C206(*; Form:C1466.promptObjectName)
	
	return Form:C1466
	
Function clearConversation() : cs:C1710._Agent
	
	This:C1470.ChatResult:=""
	This:C1470.reasoning_content:=""
	This:C1470.thoughts:=""
	This:C1470.messages:=[]
	
	If (Not:C34(This:C1470.preemptive))
		//%T-
		If (Form:C1466#Null:C1517)
			If (FORM Event:C1606.code=On Load:K2:1)
				OBJECT SET ENABLED:C1123(*; This:C1470.startObjectName; True:C214)
				OBJECT SET ENABLED:C1123(*; This:C1470.continueObjectName; False:C215)
				return This:C1470
			End if 
			This:C1470.onAfterEdit()
		End if 
		//%T-
	End if 
	
	return This:C1470
	
Function continueConversation($messages : Collection) : cs:C1710.AIKit.OpenAIChatCompletionsResult
	
	If (Form:C1466=Null:C1517)
		return 
	End if 
	
	OBJECT SET ENABLED:C1123(*; This:C1470.startObjectName; False:C215)
	OBJECT SET ENABLED:C1123(*; This:C1470.continueObjectName; False:C215)
	
	This:C1470.messages.combine($messages)
	
	This:C1470.reasoning_content:=""
	This:C1470.thoughts:=""
	
	If (This:C1470.ChatResult#"")
		This:C1470.ChatResult+="\r\r"
	End if 
	
	var $ChatCompletionsParameters : cs:C1710.AIKit.OpenAIChatCompletionsParameters
	$ChatCompletionsParameters:=cs:C1710.AIKit.OpenAIChatCompletionsParameters.new(This:C1470)
	$ChatCompletionsParameters.model:=This:C1470.model
	$ChatCompletionsParameters.stream:=This:C1470.stream
	$ChatCompletionsParameters.formula:=This:C1470.onEventStream
	
	var $ChatCompletionsResult : cs:C1710.AIKit.OpenAIChatCompletionsResult
	$ChatCompletionsResult:=This:C1470.OpenAI.chat.completions.create(This:C1470.messages; $ChatCompletionsParameters)
	
	return $ChatCompletionsResult
	
Function startConversation($messages : Collection; $onResponse : 4D:C1709.Function) : cs:C1710.AIKit.OpenAIChatCompletionsResult
	
	If (Form:C1466=Null:C1517)
		return 
	End if 
	
	OBJECT SET ENABLED:C1123(*; This:C1470.startObjectName; False:C215)
	OBJECT SET ENABLED:C1123(*; This:C1470.continueObjectName; False:C215)
	
	If (OB Instance of:C1731($onResponse; 4D:C1709.Function))
		This:C1470._onResponse:=$onResponse
	Else 
		This:C1470._onResponse:=Null:C1517
	End if 
	
	return This:C1470.clearConversation().continueConversation($messages)
	
Function onCompletion($chatCompletionsResult : cs:C1710.AIKit.OpenAIChatCompletionsResult)
	
	If (Form:C1466=Null:C1517)
		return 
	End if 
	
	If (OB Instance of:C1731(This:C1470._onResponse; 4D:C1709.Function))
		This:C1470._onResponse.call(This:C1470; $chatCompletionsResult)
	End if 
	
	If (Not:C34(This:C1470.preemptive))
		//%T-
		Form:C1466.onAfterEdit()
		var $pos : Integer
		$pos:=Length:C16(This:C1470.ChatResult)+1
		OBJECT SET VALUE:C1742(This:C1470.resultObjectName; This:C1470.ChatResult)
		HIGHLIGHT TEXT:C210(*; This:C1470.resultObjectName; $pos; $pos)
		CALL FORM:C1391(Current form window:C827; This:C1470.focusUserPrompt)
		//%T-
	End if 
	
Function onEventStream($chatCompletionsResult : cs:C1710.AIKit.OpenAIChatCompletionsResult)
	
	If (Form:C1466=Null:C1517)
		return 
	End if 
	
	If ($chatCompletionsResult.success)
		If ($chatCompletionsResult.terminated)
			//complete result
			If ($chatCompletionsResult.choice#Null:C1517)
				If ($chatCompletionsResult.choice.message=Null:C1517)  //streaming
					$chatCompletionsResult:=JSON Parse:C1218(JSON Stringify:C1217($chatCompletionsResult))
					$chatCompletionsResult.choice.message:={role: "assistant"; content: This:C1470.ChatResult}
				Else   //not streaming
					This:C1470.ChatResult+=$chatCompletionsResult.choice.message.content
				End if 
				This:C1470.messages.push($chatCompletionsResult.choice.message)
			Else 
				
			End if 
			This:C1470.onCompletion($chatCompletionsResult)
		Else 
			//partial result
			If ($chatCompletionsResult.choice#Null:C1517)
				If ($chatCompletionsResult.choice.delta.text#"")
					
					If (This:C1470.reasoning_content#"")
						This:C1470.thoughts:=This:C1470.reasoning_content
						This:C1470.reasoning_content:=""
						This:C1470.ChatResult:=This:C1470.reasoning_content
					End if 
					
					This:C1470.ChatResult+=$chatCompletionsResult.choice.delta.text
					
				Else 
					If ($chatCompletionsResult.choice.delta["reasoning_content"]#Null:C1517)
						This:C1470.reasoning_content+=$chatCompletionsResult.choice.delta["reasoning_content"]
						This:C1470.ChatResult:=This:C1470.reasoning_content
					End if 
				End if 
			Else 
				
			End if 
		End if 
	Else 
		If ($chatCompletionsResult.terminated)
			This:C1470.ChatResult+=$chatCompletionsResult.errors.extract("message").join("\r")
		End if 
	End if 
	
	If (Not:C34(This:C1470.preemptive))
		//%T-
		var $pos : Integer
		$pos:=Length:C16(This:C1470.ChatResult)+1
		OBJECT SET VALUE:C1742(This:C1470.resultObjectName; This:C1470.ChatResult)
		HIGHLIGHT TEXT:C210(*; This:C1470.resultObjectName; $pos; $pos)
		//%T-
	End if 
	
Function _isFreshConversation() : Boolean
	
	return This:C1470.messages.length=0
	
Function onDataChange() : Object
	
	Form:C1466.userPrompt:=Form:C1466.prompt.contents[Form:C1466.prompt.index]
	
	return Form:C1466
	
Function onAfterEdit() : Object
	
	var $userPrompt : Text
	$userPrompt:=OBJECT Get name:C1087(Object with focus:K67:3)="User Prompt" ? Get edited text:C655 : Form:C1466.userPrompt
	
	var $ready : Boolean
	$ready:=($userPrompt#"")
	
	OBJECT SET ENABLED:C1123(*; This:C1470.startObjectName; $ready)
	OBJECT SET ENABLED:C1123(*; This:C1470.continueObjectName; $ready)
	
	If (This:C1470._isFreshConversation())
		OBJECT SET ENABLED:C1123(*; This:C1470.continueObjectName; False:C215)
	End if 
	
	return Form:C1466