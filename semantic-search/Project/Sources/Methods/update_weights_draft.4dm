//%attributes = {"invisible":true}
var $embeddings : cs:C1710.Embeddings
$embeddings:=cs:C1710.Embeddings.me

var $stats:=["|Relevance|Min|Max|Average|"; "|:-:|-:|-:|-:|"]
$cosineSimilarity:=[[]; []; []; []]

$all:=ds:C1482.Score.all().slice(0; 5000)

For each ($score; $all)
	var $query : cs:C1710.QueryEntity
	$query:=$score._query
	var $passage : cs:C1710.PassageEntity
	$passage:=$score.passage
	$batch:=[$query.text; $passage.text]
	$embedding:=$embeddings.getMany($batch)
	$query.embedding:=$embedding[0]
	$query.save()
	$passage.embedding:=$embedding[1]
	$passage.save()
	$score.similarity:=$query.embedding.cosineSimilarity($passage.embedding)
	$score.save()
	$cosineSimilarity[$score.relevance].push($score.similarity)
End for each 

For each ($relevance; [3; 2; 1; 0])
	$stats.push(\
		"|`"+String:C10($relevance)+\
		"`|`"+String:C10($cosineSimilarity[$relevance].min(); "#0.00")+\
		"`|`"+String:C10($cosineSimilarity[$relevance].max(); "#0.00")+\
		"`|`"+String:C10($cosineSimilarity[$relevance].average(); "#0.00")+\
		"`")
End for each 

SET TEXT TO PASTEBOARD:C523($stats.join("\r"))
