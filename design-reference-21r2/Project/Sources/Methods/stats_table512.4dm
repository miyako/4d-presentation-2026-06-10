//%attributes = {}
/*

process newly imported queries

*/

var $searches : cs:C1710.SearchSelection
$searches:=ds:C1482.Search.query("similarity512 == null")
var $search : cs:C1710.SearchEntity
For each ($search; $searches)
	$search.similarity512:=$search.embeddings512.cosineSimilarity($search.passage.embeddings512)
	$search.save()
End for each 

var $stats:=["|Relevance|Min|Max|Average|"; "|:-:|-:|-:|-:|"]
var $count; $relevance : Integer
$count:=ds:C1482.Search.getCount()

For each ($relevance; [3; 2; 1; 0])
	$searches:=ds:C1482.Search.query("relevance ==:1"; $relevance)
	$stats.push(\
		"|`"+String:C10($relevance)+\
		"`|`"+String:C10($searches.min("similarity512"); "#0.00")+\
		"`|`"+String:C10($searches.max("similarity512"); "#0.00")+\
		"`|`"+String:C10($searches.average("similarity512"); "#0.00")+"`")
End for each 

SET TEXT TO PASTEBOARD:C523($stats.join("\r"))

/*

|Relevance|Min|Max|Average|
|:-:|-:|-:|-:|
|`3`|`0.44`|`0.84`|`0.68`
|`2`|`0.40`|`0.83`|`0.64`
|`1`|`0.35`|`0.83`|`0.60`
|`0`|`0.22`|`0.69`|`0.44`

GPT-5.4: 140M tokens, $17.12

*/