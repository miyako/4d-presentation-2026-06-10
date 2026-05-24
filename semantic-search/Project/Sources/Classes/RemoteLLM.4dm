property _endpoints : Object
property endpoint : Text

Class constructor($provider : Text)
	
	This:C1470._endpoints:={\
		Local: "http://127.0.0.1:8082/v1"; \
		Azure: "https://4D.openai.azure.com/openai/v1"; \
		Azure_xAI: "https://keisukemiyako-grok-resource.openai.azure.com/openai/v1/"; \
		Claude: "https://api.anthropic.com/v1"; \
		Cohere: "https://api.cohere.ai/compatibility/v1"; \
		CometAPI: "https://api.cometapi.com/v1"; \
		DeepInfra: "https://api.deepinfra.com/v1/openai"; \
		DeepSeek: "https://api.deepseek.com/v1"; \
		FireWorks: "https://api.fireworks.ai/inference/v1/"; \
		Gemini: "https://generativelanguage.googleapis.com/v1beta/openai"; \
		Groq: "https://api.groq.com/openai/v1/"; \
		HuggingFace: "https://router.huggingface.co/v1"; \
		LongCat: "https://api.longcat.chat/openai/v1/"; \
		ModelArk: "https://ark.ap-southeast.bytepluses.com/api/v3"; \
		Mistral: "https://api.mistral.ai/v1"; \
		Moonshot: "https://api.moonshot.ai/v1"; \
		NVIDIA: "https://integrate.api.nvidia.com/v1"; \
		OpenAI: ""; \
		OpenRouter: "https://openrouter.ai/api/v1"; \
		Perplexity: "https://api.perplexity.ai"; \
		xAI: "https://api.x.ai/v1"}
	
	This:C1470.endpoint:=This:C1470._endpoints[$provider]
	
Function _resolvePath($item : Object) : Object
	
	return OB Class:C1730($item).new($item.platformPath; fk platform path:K87:2)
	
Function getAccessToken($name : Text) : Text
	
	var $file : 4D:C1709.File
	$file:=This:C1470._resolvePath(Folder:C1567("/PROJECT/")).parent.folder("Secrets").file($name+".token")
	
	If ($file.exists)
		return $file.getText()
	End if 