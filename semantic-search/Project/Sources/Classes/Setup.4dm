shared singleton Class constructor
	
Function cosineSimilarityDistribution() : Text
	
	var $stats:=["|Relevance|Min|Max|Average|"; "|:-:|-:|-:|-:|"]
	$count:=ds:C1482.Score.getCount()
	For each ($relevance; [3; 2; 1; 0])
		var $scores : cs:C1710.ScoreSelection
		$scores:=ds:C1482.Score.query("relevance ==:1"; $relevance)
		$stats.push("|`"+String:C10($relevance)+"`|`"+String:C10($scores.min("similarity"); "#0.00")+\
			"`|`"+String:C10($scores.max("similarity"); "#0.00")+\
			"`|`"+String:C10($scores.average("similarity"); "#0.00")+"`")
	End for each 
	
	return $stats.join("\r")
	
Function createPassages()
	
	var $embeddings : cs:C1710.Embeddings
	$embeddings:=cs:C1710.Embeddings.me
	
	$documents:=ds:C1482.Document.all()
	For each ($document; $documents)
		
		If ($document.passages.length#0)
			continue
		End if 
		
		var $dataset : 4D:C1709.File
		$dataset:=$document.file
		
		If ($dataset=Null:C1517) || (Not:C34($dataset.exists))
			continue
		End if 
		
		var $status : Object
		$status:=$embeddings.chunk($dataset)
		
		If ($status.success=False:C215)
			continue
		End if 
		
		var $chunk : Object
		For each ($chunk; $status.embeddings)
			var $passage : cs:C1710.PassageEntity
			$passage:=ds:C1482.Passage.new()
			$passage.document:=$document
			$passage.seqID:=$chunk.index
			$passage.text:=$chunk.text
			$passage.hash:=Generate digest:C1147($passage.text; SHA1 digest:K66:2)
			$passage.embedding:=$chunk.embedding
			$passage.save()
		End for each 
		$document.reload()
	End for each 
	
Function languageDistribution() : Text
	
	$count:=ds:C1482.Score.getCount()
	var $stats:=["|Language|Data|"; "|:-:|-:|"]
	For each ($language; ["de"; "fr"; "en"])
		$length:=ds:C1482.Score.query("language == :1"; $language).length
		$stats.push("|`"+$language+\
			"`|`"+String:C10(Round:C94($length/$count; 2); "0.00")+"`|")
	End for each 
	
	return $stats.join("\r")