//%attributes = {}
//sequential vector query may diplay progress window
MESSAGES OFF:C175

var $Rn : Text
$Rn:="r1"

var $folder : 4D:C1709.Folder
$folder:=Folder:C1567([""; "DATA"; "dataset"; $Rn].join("/"))
$folder.create()

var $rerankerFolder : 4D:C1709.Folder
$rerankerFolder:=$folder.folder("reranker")
$rerankerFolder.create()

var $reranker : Object
$reranker:=cs:C1710.Reranker.new()

//use the number folders to track progress and resume
var $batch; $count : Integer
$batch:=100
$count:=$rerankerFolder.folders().length

//some queries are identical
var $hashes : Collection
$hashes:=ds:C1482.Search.all().distinct("hash")

While ($count*$batch<$hashes.length)
	var $subFolder : 4D:C1709.Folder
	$subFolder:=$rerankerFolder.folder(String:C10($count+1; "00000"))
	$subFolder.create()
	var $queryHashes : Collection
	$queryHashes:=$hashes.slice($count*$batch; ($count*$batch)+$batch)
	var $hash : Text
	For each ($hash; $queryHashes)
		var $lv : Integer
		For each ($lv; [3; 2; 1])
			//find passage(s) for this query and level; normally 1, but occasionally more 
			var $searches : cs:C1710.SearchSelection
			$searches:=ds:C1482.Search.query("hash == :1 and relevance == :2"; $hash; $lv)
			If ($searches.length=0)
				continue
			End if 
			
			var $search : cs:C1710.SearchEntity
			$search:=$searches.first()
			
			var $embedding : Object
			$embedding:=$search.embeddings
			var $positivePassages : cs:C1710.PassageSelection
			$positivePassages:=$searches.passage
			
			//document(s) to which the passage(s) belong
			var $documentIds; $positives; $negatives : Collection
			$documentIds:=$positivePassages.document.ID
			var $passage : cs:C1710.PassageEntity
			$positives:=[]
			$negatives:=[]
			//for debug purposes; not needed for training
			var $negative_relevance_scores : Collection
			$negative_relevance_scores:=[]
			If ($positivePassages.length=0)
				continue
			End if 
			//the training framework usually takes care of duplicate positives, but for hygine
			$positives:=$positivePassages.text.distinct()
			//deduplication to prevent positive/negative overlap
			var $positiveHashes : Collection
			$positiveHashes:=$positivePassages.hash.distinct()
			//cast a wide net with low threshold
			var $comparison:={vector: $search.embeddings; metric: mk cosine:K95:1; threshold: 0.35}
			$searches:=ds:C1482.Search.query("embeddings > :1 and relevance < :2 and not(passage.DocumentID in :3) and not(passage.hash in :4)"; \
				$comparison; $lv; $documentIds; $positiveHashes)
			var $negativePassages : cs:C1710.PassageSelection
			$negativePassages:=$searches.passage
			If ($negativePassages.length=0)
				//no hard negatives
				continue
			End if 
			var $top_k : Integer
			$top_k:=7
			var $f : 4D:C1709.Function
			$f:=Formula:C1597(This:C1470.embeddings.cosineSimilarity($embedding))
			$negativePassages:=$negativePassages.orderByFormula($f; dk descending:K85:32).slice(0; $top_k)
			var $text : Collection
			$text:=$negativePassages.text
			var $negativeEmbeddings : Collection
			$negativeEmbeddings:=$negativePassages.embeddings
			var $status : Object
			$status:=$reranker.rerank($search.text; $text)
			var $negativeThreshold; $positiveThreshold : Real
			$negativeThreshold:=0.65  //0.55 might be too aggressive?
			$positiveThreshold:=0.85  //0.75 might be too loose?
			If ($status.success)
				var $result : Object
				For each ($result; $status.results)
					Case of 
						: ($result.relevance_score>$negativeThreshold)
							//prune false negatives
						Else 
							var $tooSimilar : Boolean
							$tooSimilar:=False:C215
							For each ($passage; $positivePassages)
								//deduplication against positives
								If ($passage.embeddings.cosineSimilarity($negativeEmbeddings[$result.index])>$positiveThreshold)
									$tooSimilar:=True:C214
									break
								End if 
							End for each 
							If (Not:C34($tooSimilar))
								$negatives.push($text[$result.index])
								$negative_relevance_scores.push($result.relevance_score)
							End if 
					End case 
				End for each 
				
				If ($negatives.length=0)
					//no hard negatives
					continue
				End if 
				
				var $jsonl : Object
				$jsonl:={}
				$jsonl.query:=$search.text
				$jsonl.pos:=$positives
				$jsonl.neg:=$negatives
				$jsonl.relevance_score:=$negative_relevance_scores
				
				$subFolder.file(String:C10($search.getKey(); "0000000")+"-"+String:C10($lv)+".json").setText(JSON Stringify:C1217($jsonl))
				
			Else 
				continue
			End if 
		End for each 
	End for each 
	$count:=$rerankerFolder.folders().length
End while 
