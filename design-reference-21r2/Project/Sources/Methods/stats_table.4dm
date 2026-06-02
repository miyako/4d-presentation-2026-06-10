//%attributes = {}
var $searches : cs:C1710.SearchSelection
$searches:=ds:C1482.Search.query("similarity == null")
var $search : cs:C1710.SearchEntity
For each ($search; $searches)
	$search.similarity:=$search.embeddings.cosineSimilarity($search.passage.embeddings)
	$search.save()
End for each 

var $stats:=["|Relevance|Min|Max|Average|"; "|:-:|-:|-:|-:|"]
$count:=ds:C1482.Search.getCount()

For each ($relevance; [3; 2; 1; 0])
	$searches:=ds:C1482.Search.query("relevance ==:1"; $relevance)
	$stats.push(\
		"|`"+String:C10($relevance)+\
		"`|`"+String:C10($searches.min("similarity"); "#0.00")+\
		"`|`"+String:C10($searches.max("similarity"); "#0.00")+\
		"`|`"+String:C10($searches.average("similarity"); "#0.00")+"`")
End for each 

SET TEXT TO PASTEBOARD:C523($stats.join("\r"))

/*

|Relevance|Min|Max|Average|
|:-:|-:|-:|-:|
|`3`|`0.37`|`0.83`|`0.63`
|`2`|`0.33`|`0.78`|`0.59`
|`1`|`0.29`|`0.75`|`0.55`
|`0`|`0.23`|`0.70`|`0.42`

what this means

the avg. relevance order is 3 > 2 > 1 > 0 (good)
and the spread is avg. 21 (good)
relevant 1 & 0 could be lower 
relevance 2 & 1 could be further apart

*/