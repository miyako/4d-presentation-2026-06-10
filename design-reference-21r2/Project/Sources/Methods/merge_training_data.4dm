//%attributes = {}
var $Rn : Text
$Rn:="r1"

var $folder : 4D:C1709.Folder
$folder:=Folder:C1567([""; "DATA"; "dataset"; $Rn].join("/"))
ASSERT:C1129($folder.exists)

var $exportFolder : 4D:C1709.Folder
$exportFolder:=$folder.folder("export")
$exportFolder.create()

var $i; $rowsPerFile : Integer
$i:=1
$rowsPerFile:=100

$files:=$folder.files(fk recursive:K87:7).query("extension == :1"; ".json")
$lines:=[]

$posRow:=[]
$negRow:=[]

For each ($file; $files)
	$jsonl:=JSON Parse:C1218($file.getText())
	$posRow.push($jsonl.pos.length)
	$negRow.push($jsonl.neg.length)
	$lines.push(JSON Stringify:C1217($jsonl))
	If ($lines.length=$rowsPerFile)
		$exportFolder.file(String:C10($i; "00000")+".jsonl").setText($lines.join("\n"))
		$i+=1
		$lines:=[]
	End if 
End for each 

If ($lines.length#0)
	$exportFolder.file(String:C10($i; "00000")+".jsonl").setText($lines.join("\n"))
End if 

$posAvg:=$posRow.average()  //1.027397260274
$negAvg:=$negRow.average()  //2.100456621005
