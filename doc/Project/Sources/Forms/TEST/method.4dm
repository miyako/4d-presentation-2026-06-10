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
		
		Case of 
			: ($event.objectName="query")
				
				var $client : cs:C1710.AIKit.OpenAI
				$client:=cs:C1710.AIKit.OpenAI.new({baseURL: "http://127.0.0.1:"+String:C10(Storage:C1525.port.embeddings)+"/v1"})
				var $model : Text
				$model:="bge-m3"
				
				var $params : cs:C1710.AIKit.OpenAIEmbeddingsParameters
				$params:=cs:C1710.AIKit.OpenAIEmbeddingsParameters.new()
				var $batch : Object
				$batch:=$client.embeddings.create(Form:C1466.query; $model; $params)
				
				If ($batch.success)
					
					Form:C1466.vector:=$batch.embedding.embedding
					
					$queryParams:={queryPath: True:C214; queryPlan: True:C214}
					var $documents : cs:C1710.DocumentSelection
					$documents:=ds:C1482.Document.query("meta.version == :1"+\
						" and meta.language in :2"; "21-R2"; ["en"]; $queryParams)
					var $comparison : Object
					$comparison:={vector: Form:C1466.vector; metric: mk cosine:K95:1; threshold: Form:C1466.threshold}
					$documents:=$documents.query("passages.embeddings > :1"; $comparison; $queryParams)
					
					Form:C1466.documents:={col: Null:C1517; sel: Null:C1517; item: Null:C1517; pos: Null:C1517}
					Form:C1466.documents.col:=$documents
					
					GOTO OBJECT:C206(*; $event.objectName)
					
				End if 
				
			: ($event.objectName="rul.threshold") && (Form:C1466.vector#Null:C1517)
				
				$queryParams:={queryPath: True:C214; queryPlan: True:C214}
				$documents:=ds:C1482.Document.query("meta.version == :1"+\
					" and meta.language in :2"; "21-R2"; ["en"]; $queryParams)
				$comparison:={vector: Form:C1466.vector; metric: mk cosine:K95:1; threshold: Form:C1466.threshold}
				$documents:=$documents.query("passages.embeddings > :1"; $comparison; $queryParams)
				
				Form:C1466.documents:={col: Null:C1517; sel: Null:C1517; item: Null:C1517; pos: Null:C1517}
				Form:C1466.documents.col:=$documents
				
		End case 
		
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
			var $queryParams : Object
			$queryParams:={queryPath: True:C214; queryPlan: True:C214}
			$documents:=ds:C1482.Document.query("meta.version == :1"+\
				" and meta.language in :2"; "21-R2"; ["en"]; $queryParams)
			$comparison:={vector: Form:C1466.vector; metric: mk cosine:K95:1; threshold: Form:C1466.threshold}
			$documents:=$documents.query("passages.embeddings > :1"; $comparison; $queryParams)
			Form:C1466.documents:={col: Null:C1517; sel: Null:C1517; item: Null:C1517; pos: Null:C1517}
			Form:C1466.documents.col:=$documents
			
		End if 
		
End case 