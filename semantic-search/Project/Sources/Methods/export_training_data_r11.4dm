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
$folder.create()

var $rerankerFolder : 4D:C1709.Folder
$rerankerFolder:=$folder.folder("reranker")
$rerankerFolder.create()

var $reranker : Object
$reranker:=cs:C1710.Reranker.new()

$batch:=500
$count:=$rerankerFolder.folders().length

//480816
$hashes:=ds:C1482.Query.all().distinct("hash")

While ($count*$batch<$hashes.length)
	$subFolder:=$rerankerFolder.folder(String:C10($count+1; "00000"))
	$subFolder.create()
	$queryHashes:=$hashes.slice($count*$batch; ($count*$batch)+$batch)
	var $hash : Text
	For each ($hash; $queryHashes)
		$scores:=ds:C1482.Score.query("_query.hash == :1 and relevance == :2"; $hash; 3)
		If ($scores.length=0)
			//not a level 3 query
			continue
		End if 
		//is a level 3 query
		var $query : cs:C1710.QueryEntity
		$query:=$scores._query.first()
		$embedding:=$query.embedding
		$passages:=$scores.passage
		$documentIds:=$passages.document.ID
		var $passage : cs:C1710.PassageEntity
		$positives:=[]
		$negatives:=[]
		For each ($passage; $passages)
			If ($embedding.cosineSimilarity($passage.embedding)>=0.6)
				//too easy, remove from training
				continue
			End if 
			$positives.push($passage.text)
		End for each 
		If ($positives.length=0)
			continue
		End if 
		//low cosine similarity; look for more positives
		$top_k:=50
		var $comparison:={vector: $query.embedding; metric: mk cosine:K95:1; threshold: 0.5}
		$passages:=ds:C1482.Passage.query("embedding > :1 and not(DocumentID in :2)"; $comparison; $documentIds)
		If ($passages.length=0)
			//no hard negatives
			continue
		End if 
		
		$f:=Formula:C1597(This:C1470.embedding.cosineSimilarity($embedding))
		$passages:=$passages.orderByFormula($f; dk descending:K85:32).slice(0; $top_k)
		$text:=$passages.text
		$status:=$reranker.rerank($query.text; $text)
		
		If ($status.success)
			var $result : Object
			For each ($result; $status.results)
				
				Case of 
					: ($result.relevance_score>0.7)
						//mined positive
						$positives.push($text[$result.index])
					: ($result.relevance_score>0.3)
						//grey zone, remove from training
					Else 
						//hard negative (high cosine, low relevance)
						$negatives.push($text[$result.index])
				End case 
			End for each 
			
			If ($negatives.length=0)
				//no hard negatives
				continue
			End if 
			
			$jsonl:={}
			$jsonl.query:=$query.text
			$jsonl.pos:=$positives
			$jsonl.neg:=$negatives
			
			$subFolder.file(String:C10($query.getKey(); "0000000")+".json").setText(JSON Stringify:C1217($jsonl))
			
		Else 
			continue
		End if 
	End for each 
	$count:=$rerankerFolder.folders().length
End while 
