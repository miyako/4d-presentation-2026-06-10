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
$folder:=Folder:C1567([""; "DATA"; "temp"; $Rn].join("/"))
$folder.create()

var $llmFolder : 4D:C1709.Folder
$llmFolder:=Folder:C1567("/DATA/llm")
$llmFolder.create()

var $client : Object
$client:=cs:C1710.Reranker.new()

$use_reranker:=False:C215
$use_llm_only:=True:C214

$batch:=500
$count:=$folder.folders().length

//480816
$hashes:=ds:C1482.Query.all().distinct("hash")

While ($count*$batch<$hashes.length)
	$subFolder:=$folder.folder(String:C10($count+1; "00000"))
	$subFolder.create()
	$_hashes:=$hashes.slice($count*$batch; ($count*$batch)+$batch)
	For each ($hash; $_hashes)
		$scores:=ds:C1482.Score.query("_query.hash == :1 and relevance == :2"; $hash; 3)
		If ($scores.length=0)
			continue
		End if 
		//at least 1 positive query
		$cutoff:=7
		$query:=$scores._query.first()
		$passages:=$scores.passage
		$documentIds:=$passages.document.ID
		//mine hard negatives
		var $comparison:={vector: $query.embedding; metric: mk cosine:K95:1; threshold: 0.65}
		$passages:=ds:C1482.Passage.query("embedding > :1 and not(DocumentID in :2)"; $comparison; $documentIds)
		//no hard negatives
		If ($passages.length=0)
			continue
		End if 
		$i:=$query.getKey()
		$embedding:=$query.embedding
		$f:=Formula:C1597(This:C1470.embedding.cosineSimilarity($embedding))
		$passages:=$passages.orderByFormula($f; dk descending:K85:32).slice(0; $cutoff)
		$file:=$passages.document.file.first()
		$name:=Split string:C1554($file.name; "-")
		$type:=$name[0]
		$language:=$name[1]
		//let LLM judge hard negatives
		$llm_subFolder:=$llmFolder.folder(String:C10($count+1; "00000"))
		$llm_subFolder.create()
		$passages:=$passages.slice(0; 2)  //only top 2 (LLM is expensive)
		For ($ii; 0; $passages.text.length-1)
			$passage:=$passages[$ii]
			$var:={}
			$var.ID:=$i
			$var.passage:=$passage.text
			$var.passageID:=$passage.getKey()
			$var.query:=$jsonl.query
			$var.verdict:=Null:C1517
			$var.reason:=Null:C1517
			$var.type:=$type
			$var.language:=$language
			$llm_subFolder.file("llm-"+String:C10($i; "0000000")+"-"+String:C10($ii+1)+".json").setText(JSON Stringify:C1217($var))
		End for 
	End for each 
	$count:=$folder.folders().length
End while 
