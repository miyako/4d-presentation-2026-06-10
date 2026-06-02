//%attributes = {"invisible":true,"preemptive":"capable"}
#DECLARE($params : Object; $context : Object)

var $folder : 4D:C1709.Folder
var $file : 4D:C1709.File

Case of 
	: (OB Instance of:C1731($context; cs:C1710.event.error))
		ALERT:C41($context.message)
		return 
	: (OB Instance of:C1731($context; cs:C1710.event.models))
		$file:=This:C1470.options.model
	Else 
		var $huggingface : cs:C1710.event.huggingface
		$huggingface:=$params.huggingfaces.huggingfaces.first()
		$file:=$huggingface.folder.file($huggingface[($huggingface.name#"") ? "name" : "path"])
End case 

If (Not:C34($file.exists))
/*
$file is Null if the Hugging Face URL and/or file name is incorrect.
*/
	return 
End if 

Case of 
	: ($params.embeddings)
/*
$file is either the local copy from a previous session or model just downloaded.
$params is the $options object you passed to cs.llama.llama.new().
.embeddings==True if you specified an embeddings model.
*/
End case 