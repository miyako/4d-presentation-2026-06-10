//%attributes = {}
var $document : cs:C1710.DocumentEntity
For each ($document; ds:C1482.Document.all())
	ARRAY LONGINT:C221($pos; 0)
	ARRAY LONGINT:C221($len; 0)
	var $name; $language : Text
	$name:=$document.file.name
	If (Match regex:C1019("\\.([a-z]{2})"; $name; 1; $pos; $len))
		$language:=Substring:C12($name; $pos{1}; $len{1})
	Else 
		$language:="en"
	End if 
	$document.meta:={version: "21R2"; language: $language}
	$document.save()
End for each 