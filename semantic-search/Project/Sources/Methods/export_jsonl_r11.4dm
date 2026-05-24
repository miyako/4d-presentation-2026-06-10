//%attributes = {"invisible":true,"preemptive":"capable"}
var $currentMethodName : Text
$currentMethodName:=Current method name:C684

ARRAY LONGINT:C221($pos; 0)
ARRAY LONGINT:C221($len; 0)
var $Rn : Text
If (Match regex:C1019(".+?_(.\\d+)$"; $currentMethodName; 1; $pos; $len))
	$Rn:=Substring:C12($currentMethodName; $pos{1}; $len{1})
End if 

ASSERT:C1129($Rn#"")

var $folder : 4D:C1709.Folder
$folder:=Folder:C1567([""; "DATA"; "dataset"; $Rn].join("/"))

ASSERT:C1129($folder.exists)

var $exportFolder : 4D:C1709.Folder
$exportFolder:=Folder:C1567([""; "DATA"; "dataset"; $Rn].join("/"))
$exportFolder.create()
$i:=1

//8302
$files:=$folder.files(fk recursive:K87:7).query("extension == :1"; ".json")
$lines:=[]

$posRow:=[]
$negRow:=[]

For each ($file; $files)
	$jsonl:=JSON Parse:C1218($file.getText())
	$posRow.push($jsonl.pos.length)
	$negRow.push($jsonl.neg.length)
	$lines.push(JSON Stringify:C1217($jsonl))
	If ($lines.length=1000)
		$exportFolder.file(String:C10($i; "0000")+".jsonl").setText($lines.join("\n"))
		$i+=1
		$lines:=[]
	End if 
End for each 

If ($lines.length#0)
	$exportFolder.file(String:C10($i; "0000")+".jsonl").setText($lines.join("\n"))
End if 

$posAvg:=$posRow.average()  //4.635389062876
$negAvg:=$negRow.average()  //2.848952059745
