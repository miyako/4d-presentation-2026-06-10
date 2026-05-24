property llama : cs:C1710.AIKit.OpenAI

shared singleton Class constructor
	
	var $llama : cs:C1710.AIKit.OpenAI
	$llama:=cs:C1710.AIKit.OpenAI.new()
	$llama.baseURL:="http://127.0.0.1:"+String:C10(Storage:C1525.port.embeddings)+"/v1"
	
	This:C1470.llama:=OB Copy:C1225($llama; ck shared:K85:29)
	
Function chunk($file : 4D:C1709.File)->$status : Object
	
	$status:={success: False:C215}
	
	If ($file=Null:C1517) || (Not:C34(OB Instance of:C1731($file; 4D:C1709.File))) || (Not:C34($file.exists))
		$status.error:="Invalid document."
		return $status
	End if 
	
	var $type : Integer
	Case of 
		: ($file.extension=".txt")
			$type:=Extract Document TXT
		: ($file.extension=".docx")
			$type:=Extract Document DOCX
		Else 
			$status.error:="Invalid document type."
			return $status
	End case 
	
	var $extract; $batch : Object
	$extract:=This:C1470._extract($file; $type)
	If ($extract.success)
		var $input : Collection
		$input:=$extract.input
		$batch:=This:C1470._batch($input)
		If ($batch.success)
			$status.embeddings:=$batch.embeddings
			var $embeddings : Object
			var $i:=0
			For each ($embeddings; $status.embeddings)
				$embeddings.text:=$input.at($i)
				$i+=1
			End for each 
			$status.success:=True:C214
		Else 
			$status.error:=$batch.errors.extract("body.error.message").join("\r")
		End if 
	Else 
		
	End if 
	
Function _extract($file : 4D:C1709.File; $type : Integer) : Object
	
/*
deliberately cap the prompt length at 500
(model can handle up to n_ctx_train=8192)
to avoid token dilusion and attention deficit
subtract 2 from ubatch for [CLS] and [SEP]
*/
	
	var $task; $extract : Object
	$task:={file: $file; \
		text_as_tokens: False:C215; \
		tokens_length: 1022; \
		overlap_ratio: 0.09; \
		unique_values_only: True:C214; \
		pooling_mode: Extract Pooling Mode CLS}
	$extract:=Extract($type; Extract Output Collection; $task)
	
	return $extract
	
Function getOne($input : Text) : 4D:C1709.Vector
	
	var $batch : cs:C1710.AIKit.OpenAIEmbeddingsResult
	$batch:=This:C1470.llama.embeddings.create($input)
	
	If ($batch.success)
		return $batch.embedding.embedding
	End if 
	
Function getMany($input : Collection) : Collection
	
	var $batch : cs:C1710.AIKit.OpenAIEmbeddingsResult
	$batch:=This:C1470.llama.embeddings.create($input)
	
	If ($batch.success)
		return $batch.embeddings.extract("embedding")
	End if 
	
Function _batch($input : Collection) : Object
	
	var $batch : cs:C1710.AIKit.OpenAIEmbeddingsResult
	$batch:=This:C1470.llama.embeddings.create($input)
	
	return $batch