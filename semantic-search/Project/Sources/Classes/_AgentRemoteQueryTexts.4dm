Class extends _AgentRemote

Class constructor($provider : Text; $model : Text)
	
	Super:C1705($provider; $model)
	
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
	$response_format.json_schema.name:="QueryTexts"
	$response_format.json_schema.strict:=True:C214
	$response_format.json_schema.schema:={}
	$response_format.json_schema.schema.type:="object"
	$response_format.json_schema.schema.properties:={}
	$response_format.json_schema.schema.required:=["texts"]
	$response_format.json_schema.schema.additionalProperties:=False:C215
	$response_format.json_schema.schema.properties.texts:={}
	$response_format.json_schema.schema.properties.texts.type:="array"
	$response_format.json_schema.schema.properties.texts.items:={}
	$response_format.json_schema.schema.properties.texts.items.type:="object"
	$response_format.json_schema.schema.properties.texts.items.properties:={}
	$response_format.json_schema.schema.properties.texts.items.required:=["text"; "language"; "relevance"]
	$response_format.json_schema.schema.properties.texts.items.additionalProperties:=False:C215
	$response_format.json_schema.schema.properties.texts.items.properties.text:={type: "string"}
	$response_format.json_schema.schema.properties.texts.items.properties.language:={type: "string"; enum: ["de"; "fr"; "en"]}
	$response_format.json_schema.schema.properties.texts.items.properties.relevance:={type: "integer"; enum: [0; 1; 2; 3]}
	
	$ChatCompletionsParameters.response_format:=$response_format
	
	If (This:C1470.provider="Cohere")
		OB REMOVE:C1226($ChatCompletionsParameters; "n")
	End if 
	
	var $ChatCompletionsResult : cs:C1710.AIKit.OpenAIChatCompletionsResult
	$ChatCompletionsResult:=This:C1470.OpenAI.chat.completions.create(This:C1470.messages; $ChatCompletionsParameters)
	
	return $ChatCompletionsResult