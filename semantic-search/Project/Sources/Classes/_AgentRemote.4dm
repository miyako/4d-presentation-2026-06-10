property OpenAI : cs:C1710.AIKit.OpenAI
property ChatResult : Text
property model : Text
property preemptive : Boolean
property messages : Collection
property _onResponse : 4D:C1709.Function
property stream : Boolean
property reasoning_content : Text
property apiKey : Text
property provider : Text
property task : Text
property name : Text
property api : Text
property passage : Text
property query : Text
property passage_hash : Text
property query_hash : Text
property file : 4D:C1709.File

Class constructor($provider : Text; $model : Text)
	
	var $OpenAI : cs:C1710.RemoteLLM
	$OpenAI:=cs:C1710.RemoteLLM.new($provider)
	var $baseURL; $apiKey : Text
	$baseURL:=$OpenAI.endpoint
	$apiKey:=$OpenAI.getAccessToken($provider)
	This:C1470.stream:=False:C215
	This:C1470.model:=$model
	This:C1470.provider:=$provider
	This:C1470.OpenAI:=cs:C1710.AIKit.OpenAI.new({baseURL: $baseURL; apiKey: $apiKey})
	This:C1470.preemptive:=Process info:C1843(Current process:C322).preemptive
	
Function clearConversation() : cs:C1710._AgentRemote
	
	This:C1470.ChatResult:=""
	This:C1470.reasoning_content:=""
	This:C1470.messages:=[]
	
	return This:C1470
	
Function continueConversation($messages : Collection) : cs:C1710.AIKit.OpenAIChatCompletionsResult
	
	This:C1470.messages.combine($messages)
	
	This:C1470.reasoning_content:=""
	
	If (This:C1470.ChatResult#"")
		This:C1470.ChatResult+="\r\r"
	End if 
	
	var $ChatCompletionsParameters : cs:C1710.AIKit.OpenAIChatCompletionsParameters
	$ChatCompletionsParameters:=cs:C1710.AIKit.OpenAIChatCompletionsParameters.new(This:C1470)
	$ChatCompletionsParameters.model:=This:C1470.model
	$ChatCompletionsParameters.stream:=This:C1470.stream
	$ChatCompletionsParameters.formula:=This:C1470.onEventStream
	
	var $response_format:={type: "json_schema"; json_schema: {}}
	$response_format.json_schema:={}
	$response_format.json_schema.name:="ChatML"
	$response_format.json_schema.strict:=True:C214
	$response_format.json_schema.schema:={}
	$response_format.json_schema.schema.type:="object"
	$response_format.json_schema.schema.properties:={}
	$response_format.json_schema.schema.required:=["messages"]
	$response_format.json_schema.schema.additionalProperties:=False:C215
	$response_format.json_schema.schema.properties.messages:={}
	$response_format.json_schema.schema.properties.messages.type:="array"
	$response_format.json_schema.schema.properties.messages.items:={}
	$response_format.json_schema.schema.properties.messages.items.type:="object"
	$response_format.json_schema.schema.properties.messages.items.properties:={}
	$response_format.json_schema.schema.properties.messages.items.required:=["role"; "content"]
	$response_format.json_schema.schema.properties.messages.items.additionalProperties:=False:C215
	$response_format.json_schema.schema.properties.messages.items.properties.role:={type: "string"}
	$response_format.json_schema.schema.properties.messages.items.properties.content:={type: "string"}
	$ChatCompletionsParameters.response_format:=$response_format
	
	If (This:C1470.provider="Cohere")
		OB REMOVE:C1226($ChatCompletionsParameters; "n")
	End if 
	
	var $ChatCompletionsResult : cs:C1710.AIKit.OpenAIChatCompletionsResult
	$ChatCompletionsResult:=This:C1470.OpenAI.chat.completions.create(This:C1470.messages; $ChatCompletionsParameters)
	
	return $ChatCompletionsResult
	
Function startConversation($messages : Collection; $onResponse : 4D:C1709.Function) : cs:C1710.AIKit.OpenAIChatCompletionsResult
	
	If (OB Instance of:C1731($onResponse; 4D:C1709.Function))
		This:C1470._onResponse:=$onResponse
	Else 
		This:C1470._onResponse:=Null:C1517
	End if 
	
	return This:C1470.clearConversation().continueConversation($messages)
	
Function onCompletion($chatCompletionsResult : cs:C1710.AIKit.OpenAIChatCompletionsResult)
	
	If (OB Instance of:C1731(This:C1470._onResponse; 4D:C1709.Function))
		This:C1470._onResponse.call(This:C1470; $chatCompletionsResult)
	End if 
	
Function onEventStream($chatCompletionsResult : cs:C1710.AIKit.OpenAIChatCompletionsResult)
	
	If ($chatCompletionsResult.success)
		If ($chatCompletionsResult.terminated)
			//complete result
			If ($chatCompletionsResult.choice#Null:C1517)
				If ($chatCompletionsResult.choice.message=Null:C1517)  //streaming
					$chatCompletionsResult:=JSON Parse:C1218(JSON Stringify:C1217($chatCompletionsResult))
					$chatCompletionsResult.choice.message:={role: "assistant"; content: This:C1470.ChatResult}
				Else   //not streaming
					If ($chatCompletionsResult.choice.message.content#Null:C1517)
						This:C1470.ChatResult+=$chatCompletionsResult.choice.message.content
					End if 
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
			DELAY PROCESS:C323(Current process:C322; 60*30)
			If (OB Instance of:C1731(This:C1470._onResponse; 4D:C1709.Function))
				This:C1470._onResponse.call(This:C1470; $chatCompletionsResult)
			End if 
		End if 
	End if 
	
Function _isFreshConversation() : Boolean
	
	return This:C1470.messages.length=0
	