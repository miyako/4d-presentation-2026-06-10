If (Form event code:C388=On Clicked:K2:4)
	
	var $messages : Collection
	$messages:=[]
	$messages.push({role: "system"; content: Form:C1466.systemPrompt})
	$messages.push({role: "user"; content: Form:C1466.userPrompt})
	
	Form:C1466.startConversation($messages)
	
	OBJECT SET ENABLED:C1123(*; "btn.@"; False:C215)
	
End if 