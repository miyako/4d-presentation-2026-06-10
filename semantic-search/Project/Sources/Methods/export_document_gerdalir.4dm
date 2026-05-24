//%attributes = {"invisible":true}
var $target_folder : 4D:C1709.Folder
$target_folder:=Folder:C1567(fk data folder:K87:12).folder("query_datasets")
$target_folder.create()

var $corpus : Collection  //3095384 rows
$corpus:=Storage:C1525.corpus

If ($corpus=Null:C1517)
	$corpus:=Split string:C1554(File:C1566("/DATA/GerDaLIR/corpus/corpus.tsv").getText("utf-8"; Document with LF:K24:22); "\n")
	Use (Storage:C1525)
		Storage:C1525.corpus:=$corpus.copy(ck shared:K85:29)
	End use 
End if 

var $line; $text; $hash; $q_id : Text
var $row : Collection
For each ($corp; $corpus)
	$row:=Split string:C1554($corp; "\t")
	If ($row.length#2)
		continue
	End if 
	var $d_id; $doc_hash : Text
	$d_id:=$row[0]
	$text:=$row[1]
	$hash:=Generate digest:C1147($text; SHA1 digest:K66:2)
	var $document : cs:C1710.DocumentEntity
	$document:=ds:C1482.Document.query("hash == :1"; $hash).first()
	If ($document=Null:C1517)
		$document:=ds:C1482.Document.new()
		$document.hash:=$hash
	End if 
	var $i:=1
	var $fileName : Text
	$fileName:=String:C10($i; "0000000")
	While ($target_folder.file("case-de-"+$fileName+".txt").exists)
		$i+=1
		$fileName:=String:C10($i; "0000000")
	End while 
	$file:=$target_folder.file("case-de-"+$fileName+".txt")
	$file.setText($text)
	$document.file:=$file
	$document.save()
	
End for each 