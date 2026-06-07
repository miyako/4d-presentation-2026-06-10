//%attributes = {}
var $search : cs:C1710.SearchEntity
For each ($search; ds:C1482.Search.all())
	$search.embeddings512:=4D:C1709.Vector.new(($search.embeddings.toCollection().slice(0; 512)))
	$search.save()
End for each 

var $passage : cs:C1710.PassageEntity
For each ($passage; ds:C1482.Passage.all())
	$passage.embeddings512:=4D:C1709.Vector.new(($passage.embeddings.toCollection().slice(0; 512)))
	$passage.save()
End for each 

