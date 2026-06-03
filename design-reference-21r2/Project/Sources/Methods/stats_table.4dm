//%attributes = {}
/*

process newly imported queries

*/

var $searches : cs:C1710.SearchSelection
$searches:=ds:C1482.Search.query("similarity == null")
var $search : cs:C1710.SearchEntity
For each ($search; $searches)
	$search.similarity:=$search.embeddings.cosineSimilarity($search.passage.embeddings)
	$search.save()
End for each 

var $stats:=["|Relevance|Min|Max|Average|"; "|:-:|-:|-:|-:|"]
var $count; $relevance : Integer
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
|`3`|`0.36`|`0.83`|`0.63`
|`2`|`0.32`|`0.78`|`0.59`
|`1`|`0.23`|`0.76`|`0.55`
|`0`|`0.23`|`0.70`|`0.42`

what this means

the avg. relevance order is 3 > 2 > 1 > 0 (good)
the spread between lv.3 and lv.0 is pretty wide (good)
the spread between lv.2 and lv.1 is not very wide (not good)
lv.1 and lv.0 are relatively high (not good)

what we expect in fine-tuning

widen the spread betwen levels
retain the ranking
depress lv.0 even more

*/