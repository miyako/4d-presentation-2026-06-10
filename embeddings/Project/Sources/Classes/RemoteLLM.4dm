property _baseURLs : Object
property apiKey : Text
property _provider : Text
property baseURL : Text

Class constructor($_provider : Text)
	
	If ($_provider="")
		$_provider:="OpenAI"
	End if 
	
	This:C1470._provider:=$_provider
	This:C1470._baseURLs:={\
		Cohere: "https://api.cohere.ai/compatibility/v1"; \
		Gemini: "https://generativelanguage.googleapis.com/v1beta/openai"; \
		OpenAI: ""; \
		xAI: "https://api.x.ai/v1"}
	
	This:C1470.baseURL:=This:C1470._baseURLs[This:C1470._provider]
	
	var $file : 4D:C1709.File
	$file:=This:C1470._resolvePath(Folder:C1567("/PROJECT/")).parent.folder("Secrets").file(This:C1470._provider+".token")
	
	If ($file.exists)
		This:C1470.apiKey:=$file.getText()
	End if 
	
Function _resolvePath($item : Object) : Object
	
	return OB Class:C1730($item).new($item.platformPath; fk platform path:K87:2)