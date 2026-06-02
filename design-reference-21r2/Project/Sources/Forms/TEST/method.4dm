var $event : Object
$event:=FORM Event:C1606

Case of 
	: ($event.code=On Double Clicked:K2:5)
		
		If ($event.objectName="documents")
			If (Form:C1466.documents.item#Null:C1517)
				OPEN URL:C673(Form:C1466.documents.item.file.platformPath)
			End if 
		End if 
		
	: ($event.code=On Load:K2:1)
		
		Form:C1466.threshold:=0.6
		
	: ($event.code=On Data Change:K2:15)
		
		If ($event.objectName="rul.threshold") && (Form:C1466.vector#Null:C1517)
			
			var $comparison:={vector: Form:C1466.vector; metric: mk cosine:K95:1; threshold: Form:C1466.threshold}
			$documents:=ds:C1482.Document.query("passages.embeddings > :1"; $comparison)
			Form:C1466.documents:={col: Null:C1517; sel: Null:C1517; item: Null:C1517; pos: Null:C1517}
			Form:C1466.documents.col:=$documents
			
		End if 
		
	: ($event.code=On Clicked:K2:4)
		
		If ($event.objectName="btn.rel.@")
			
			var $relevance : Integer
			ARRAY LONGINT:C221($pos; 0)
			ARRAY LONGINT:C221($len; 0)
			If (Match regex:C1019("\\.(\\d)"; $event.objectName; 1; $pos; $len))
				$relevance:=Num:C11(Substring:C12($event.objectName; $pos{1}; $len{1}))
			End if 
			var $searches : cs:C1710.SearchSelection
			$searches:=ds:C1482.Search.query("relevance == :1"; $relevance)
			var $search : cs:C1710.SearchEntity
			$search:=$searches.at(Random:C100%$searches.length)
			
			If ($relevance>1)
				Form:C1466.document:=$search.passage.document
			Else 
				Form:C1466.document:=Null:C1517
			End if 
			
			Form:C1466.query:=$search.text
			Form:C1466.vector:=$search.embeddings
			
			$comparison:={vector: Form:C1466.vector; metric: mk cosine:K95:1; threshold: Form:C1466.threshold}
			$documents:=ds:C1482.Document.query("passages.embeddings > :1"; $comparison)
			Form:C1466.documents:={col: Null:C1517; sel: Null:C1517; item: Null:C1517; pos: Null:C1517}
			Form:C1466.documents.col:=$documents
			
		End if 
		
End case 