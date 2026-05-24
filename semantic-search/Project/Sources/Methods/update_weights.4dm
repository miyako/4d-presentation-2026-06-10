//%attributes = {"invisible":true}
var $embeddings : cs:C1710.Embeddings
$embeddings:=cs:C1710.Embeddings.me

$batches:=16

$all:=ds:C1482.Passage.all()

For ($i; 0; $all.length; $batches)
	$batch:=$all.slice($i; $i+$batches)
	$embedding:=$embeddings.getMany($batch.text)
	For each ($passage; $batch)
		$passage.embedding:=$embedding.shift()
		$passage.save()
	End for each 
End for 

$all:=ds:C1482.Query.all()

For ($i; 0; $all.length; $batches)
	$batch:=$all.slice($i; $i+$batches)
	$embedding:=$embeddings.getMany($batch.text)
	For each ($query; $batch)
		$query.embedding:=$embedding.shift()
		$query.save()
	End for each 
End for 

$all:=ds:C1482.Score.all()

For each ($score; $all)
	$score.similarity:=$score._query.embedding.cosineSimilarity($score.passage.embedding)
	$score.save()
End for each 

