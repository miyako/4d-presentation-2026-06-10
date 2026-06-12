//%attributes = {}
/*

process newly imported queries

*/

var $searches : cs:C1710.SearchSelection
$searches:=ds:C1482.Search.all()  //("similarity == null")
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

original BAAI/BGE-M3

|Relevance|Min|Max|Average|
|:-:|-:|-:|-:|
|`3`|`0.39`|`0.83`|`0.65`
|`2`|`0.34`|`0.80`|`0.62`
|`1`|`0.31`|`0.82`|`0.58`
|`0`|`0.21`|`0.65`|`0.40`

after LoRA r1

|Relevance|Min|Max|Average|
|:-:|-:|-:|-:|
|`3`|`0.42`|`0.89`|`0.67`
|`2`|`0.23`|`0.85`|`0.63`
|`1`|`0.27`|`0.83`|`0.58`
|`0`|`0.05`|`0.70`|`0.31`

after LoRA r2

|Relevance|Min|Max|Average|
|:-:|-:|-:|-:|
|`3`| `0.32`|`0.87`|`0.65`
|`2`| `0.02`|`0.83`|`0.61`
|`1`| `0.03`|`0.82`|`0.54`
|`0`|`-0.09`|`0.60`|`0.19`

after LoRA r2+import

|Relevance|Min|Max|Average|
|:-:|-:|-:|-:|
|`3`| `0.20`|`0.87`|`0.63`
|`2`| `0.02`|`0.83`|`0.59`
|`1`| `0.03`|`0.82`|`0.52`
|`0`|`-0.09`|`0.62`|`0.19`



after LoRA r3

|Relevance|Min|Max|Average|
|:-:|-:|-:|-:|
|`3`| `0.33`|`0.78`|`0.56`
|`2`|`-0.01`|`0.73`|`0.52`
|`1`| `0.03`|`0.68`|`0.46`
|`0`|`-0.08`|`0.58`|`0.18`

*/