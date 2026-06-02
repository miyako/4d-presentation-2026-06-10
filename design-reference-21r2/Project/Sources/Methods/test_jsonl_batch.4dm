//%attributes = {}
var $folder : 4D:C1709.Folder
$folder:=Folder:C1567("/DATA/prompts/queries")
var $systemPrompt; $userPrompt; $userPromptTemplate : Text
$systemPrompt:=$folder.file("system.txt").getText()
$userPromptTemplate:=$folder.file("user.txt").getText()

var $jsonl : Object
$jsonl:={requests: []}

var $passages : cs:C1710.PassageSelection
var $passage : cs:C1710.PassageEntity
$passages:=ds:C1482.Passage.query("searches == null")

For each ($passage; $passages)
	var $name; $language : Text
	$name:=$passage.document.file.name
	ARRAY LONGINT:C221($pos; 0)
	ARRAY LONGINT:C221($len; 0)
	If (Match regex:C1019("\\.([a-z]{2})$"; $name; 1; $pos; $len))
		$language:=Substring:C12($name; $pos{1}; $len{1})
	Else 
		$language:="en"
	End if 
	var $text; $version : Text
	$text:=$passage.text
	$version:="21R2"
	PROCESS 4D TAGS:C816($userPromptTemplate; $userPrompt; {text: $text; language: $language; version: $version})
	var $json : Object
	$json:={params: {}}
	$json.custom_id:="passage-"+String:C10($passage.getKey())
	$json.params.model:="claude-sonnet-4-6"  //need strong reasoning
	$json.params.max_tokens:=1500
	$json.params.system:=$systemPrompt
	$json.params.messages:=[{role: "user"; content: $userPrompt}]
	$jsonl.requests.push($json)
End for each 

Folder:C1567(fk desktop folder:K87:19).file("792.jsonl").setText(JSON Stringify:C1217($jsonl))