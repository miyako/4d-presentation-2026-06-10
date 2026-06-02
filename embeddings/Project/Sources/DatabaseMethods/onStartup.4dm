Use (Storage:C1525)
	Storage:C1525.ports:=New shared object:C1526(\
		"embeddinggemma"; 9001; \
		"m3"; 9002; \
		"ettin"; 9003; \
		"granite"; 9004; \
		"nomic"; 9005; \
		"e5"; 9006; \
		"qwen"; 9007; \
		"graniteEn"; 9008; \
		"nomicEn"; 9009; \
		"e5En"; 9010; \
		"arctic"; 9011; \
		"gte"; 9012; \
		"arcticEn"; 9013)
End use 

var $llama : cs:C1710.llama.llama
var $huggingfaces : cs:C1710.event.huggingfaces
var $embeddings; $rerank : cs:C1710.event.huggingface
var $homeFolder : 4D:C1709.Folder

var $file : 4D:C1709.File
var $URL : Text
var $port : Integer

var $event : cs:C1710.event.event
$event:=cs:C1710.event.event.new()

$event.onError:=Formula:C1597(OnModelDownloaded)
$event.onSuccess:=Formula:C1597(OnModelDownloaded)
$event.onData:=Formula:C1597(LOG EVENT:C667(Into 4D debug message:K38:5; This:C1470.file.fullName+":"+String:C10((This:C1470.range.end/This:C1470.range.length)*100; "###.00%")))
$event.onResponse:=Formula:C1597(LOG EVENT:C667(Into 4D debug message:K38:5; This:C1470.file.fullName+":download complete"))
$event.onTerminate:=Formula:C1597(LOG EVENT:C667(Into 4D debug message:K38:5; (["process"; $1.pid; "terminated!"].join(" "))))

$homeFolder:=Folder:C1567(fk home folder:K87:24).folder(".GGUF")
var $max_position_embeddings; $batch_size; $parallel : Integer
var $ubatch_size; $n_gpu_layers; $threads; $threads_batch; $batches : Integer

var $folder : 4D:C1709.Folder
var $logFile : 4D:C1709.File
var $path; $pooling : Text
var $options : Object

$max_position_embeddings:=512
$batch_size:=$max_position_embeddings
$ubatch_size:=$max_position_embeddings
$n_gpu_layers:=-1

$batches:=2
$threads:=2
$threads_batch:=2

If (False:C215)
	
	$folder:=$homeFolder.folder("embeddinggemma-300m")
	$path:="embeddinggemma-300m-Q8_0.gguf"
	$URL:="keisuke-miyako/embeddinggemma-300m-gguf-q8_0"
	
	$pooling:="mean"
	
/*
	
埋め込みモデルのハイパーパラメーター
	
以下を間違えると起動しない
	
- pooling
- ctx_size
- ubatch_size
	
以下はパフォーマンスを左右する
	
- n_gpu_layers
- ctx_size
- threads 
- threads_batch 
	
注記
	
- ubatch_sizeはbatch_sizeの倍数であるべき
- parallelはスロット数（単一リクエストで送信するバッチ数に合わせる）
- threads_httpには+1の余裕を持たせると良い（healthエンドポイントのため）
- ctx_sizeにはプロンプト全体が収まらなければならない
- threadsはデコーダー（出力）
- threads_batchはエンコーダー（入力）
- threads,threads_batchはCPUのコア数（GPUではない）
	
埋め込みモデル特有の注意点
	
- ubatch_sizeにプロンプト(=ctx_size)がまるごと収まらなければならない
	
 */
	
	$logFile:=$folder.file("llama.log")
	$folder.create()
	If (Not:C34($logFile.exists))
		$logFile.setContent(4D:C1709.Blob.new())
	End if 
	
	$port:=Storage:C1525.ports.embeddinggemma
	$options:={\
		embeddings: True:C214; \
		pooling: $pooling; \
		ctx_size: $max_position_embeddings*$batches; \
		batch_size: $batch_size*$batches; \
		ubatch_size: $ubatch_size; \
		parallel: $batches; \
		threads: $threads; \
		threads_batch: $threads_batch; \
		threads_http: $batches+1; \
		log_file: $logFile; \
		log_disable: False:C215; \
		n_gpu_layers: $n_gpu_layers}
	
	$embeddings:=cs:C1710.event.huggingface.new($folder; $URL; $path)
	$huggingfaces:=cs:C1710.event.huggingfaces.new([$embeddings])
	$llama:=cs:C1710.llama.llama.new($port; $huggingfaces; $homeFolder; $options; $event)
	
End if 

If (True:C214)
	
	$folder:=$homeFolder.folder("bge-m3")
	$path:="bge-m3-Q8_0.gguf"
	$URL:="keisuke-miyako/bge-m3-gguf-q8_0"
	
	$pooling:="cls"
	
	$logFile:=$folder.file("llama.log")
	$folder.create()
	If (Not:C34($logFile.exists))
		$logFile.setContent(4D:C1709.Blob.new())
	End if 
	
	$port:=Storage:C1525.ports.m3
	$options:={\
		embeddings: True:C214; \
		pooling: $pooling; \
		ctx_size: $max_position_embeddings*$batches; \
		batch_size: $batch_size*$batches; \
		ubatch_size: $ubatch_size; \
		parallel: $batches; \
		threads: $threads; \
		threads_batch: $threads_batch; \
		threads_http: $batches+1; \
		log_file: $logFile; \
		log_disable: False:C215; \
		n_gpu_layers: $n_gpu_layers}
	
	$embeddings:=cs:C1710.event.huggingface.new($folder; $URL; $path)
	$huggingfaces:=cs:C1710.event.huggingfaces.new([$embeddings])
	$llama:=cs:C1710.llama.llama.new($port; $huggingfaces; $homeFolder; $options; $event)
	
End if 

If (False:C215)
	
	$folder:=$homeFolder.folder("ettin-encoder")
	$path:="ettin-encoder-400m-Q8_0.gguf"
	$URL:="keisuke-miyako/ettin-encoder-gguf"
	
	$pooling:="mean"
	
	$logFile:=$folder.file("llama.log")
	$folder.create()
	If (Not:C34($logFile.exists))
		$logFile.setContent(4D:C1709.Blob.new())
	End if 
	
	$port:=Storage:C1525.ports.ettin
	$options:={\
		embeddings: True:C214; \
		pooling: $pooling; \
		ctx_size: $max_position_embeddings*$batches; \
		batch_size: $batch_size*$batches; \
		ubatch_size: $ubatch_size; \
		parallel: $batches; \
		threads: $threads; \
		threads_batch: $threads_batch; \
		threads_http: $batches+1; \
		log_file: $logFile; \
		log_disable: False:C215; \
		n_gpu_layers: $n_gpu_layers}
	
	$embeddings:=cs:C1710.event.huggingface.new($folder; $URL; $path)
	$huggingfaces:=cs:C1710.event.huggingfaces.new([$embeddings])
	$llama:=cs:C1710.llama.llama.new($port; $huggingfaces; $homeFolder; $options; $event)
	
End if 

If (False:C215)
	
	$folder:=$homeFolder.folder("granite-embedding-multilingual-r2")
	$path:="granite-embedding-311m-multilingual-r2-Q8_0.gguf"
	$URL:="keisuke-miyako/granite-embedding-multilingual-r2-gguf"
	
	$pooling:="cls"
	
	$logFile:=$folder.file("llama.log")
	$folder.create()
	If (Not:C34($logFile.exists))
		$logFile.setContent(4D:C1709.Blob.new())
	End if 
	
	$port:=Storage:C1525.ports.granite
	$options:={\
		embeddings: True:C214; \
		pooling: $pooling; \
		ctx_size: $max_position_embeddings*$batches; \
		batch_size: $batch_size*$batches; \
		ubatch_size: $ubatch_size; \
		parallel: $batches; \
		threads: $threads; \
		threads_batch: $threads_batch; \
		threads_http: $batches+1; \
		log_file: $logFile; \
		log_disable: False:C215; \
		n_gpu_layers: $n_gpu_layers}
	
	$embeddings:=cs:C1710.event.huggingface.new($folder; $URL; $path)
	$huggingfaces:=cs:C1710.event.huggingfaces.new([$embeddings])
	$llama:=cs:C1710.llama.llama.new($port; $huggingfaces; $homeFolder; $options; $event)
	
End if 

If (False:C215)
	
	$folder:=$homeFolder.folder("nomic-embed-text-v2-moe")
	$path:="nomic-embed-text-v2-moe-Q8_0.gguf"
	$URL:="keisuke-miyako/nomic-embed-text-v2-moe-gguf-q8_0"
	
	$pooling:="mean"
	
	$logFile:=$folder.file("llama.log")
	$folder.create()
	If (Not:C34($logFile.exists))
		$logFile.setContent(4D:C1709.Blob.new())
	End if 
	
	$port:=Storage:C1525.ports.nomic
	$options:={\
		embeddings: True:C214; \
		pooling: $pooling; \
		ctx_size: $max_position_embeddings*$batches; \
		batch_size: $batch_size*$batches; \
		ubatch_size: $ubatch_size; \
		parallel: $batches; \
		threads: $threads; \
		threads_batch: $threads_batch; \
		threads_http: $batches+1; \
		log_file: $logFile; \
		log_disable: False:C215; \
		n_gpu_layers: $n_gpu_layers}
	
	$embeddings:=cs:C1710.event.huggingface.new($folder; $URL; $path)
	$huggingfaces:=cs:C1710.event.huggingfaces.new([$embeddings])
	$llama:=cs:C1710.llama.llama.new($port; $huggingfaces; $homeFolder; $options; $event)
	
End if 

If (False:C215)
	
	$folder:=$homeFolder.folder("multilingual-e5-base")
	$path:="multilingual-e5-base-Q8_0.gguf"
	$URL:="keisuke-miyako/multilingual-e5-base-gguf-q8_0"
	
	$pooling:="mean"
	
	$logFile:=$folder.file("llama.log")
	$folder.create()
	If (Not:C34($logFile.exists))
		$logFile.setContent(4D:C1709.Blob.new())
	End if 
	
	$port:=Storage:C1525.ports.e5
	$options:={\
		embeddings: True:C214; \
		pooling: $pooling; \
		ctx_size: $max_position_embeddings*$batches; \
		batch_size: $batch_size*$batches; \
		ubatch_size: $ubatch_size; \
		parallel: $batches; \
		threads: $threads; \
		threads_batch: $threads_batch; \
		threads_http: $batches+1; \
		log_file: $logFile; \
		log_disable: False:C215; \
		n_gpu_layers: $n_gpu_layers}
	
	$embeddings:=cs:C1710.event.huggingface.new($folder; $URL; $path)
	$huggingfaces:=cs:C1710.event.huggingfaces.new([$embeddings])
	$llama:=cs:C1710.llama.llama.new($port; $huggingfaces; $homeFolder; $options; $event)
	
End if 

If (False:C215)
	
	$folder:=$homeFolder.folder("Qwen3-Embedding-0.6B")
	$path:="Qwen3-Embedding-0.6B-Q8_0.gguf"
	$URL:="keisuke-miyako/Qwen3-Embedding-0.6B-gguf-q8_0"
	
	$pooling:="last"
	
	$logFile:=$folder.file("llama.log")
	$folder.create()
	If (Not:C34($logFile.exists))
		$logFile.setContent(4D:C1709.Blob.new())
	End if 
	
	$port:=Storage:C1525.ports.qwen
	$options:={\
		embeddings: True:C214; \
		pooling: $pooling; \
		ctx_size: $max_position_embeddings*$batches; \
		batch_size: $batch_size*$batches; \
		ubatch_size: $ubatch_size; \
		parallel: $batches; \
		threads: $threads; \
		threads_batch: $threads_batch; \
		threads_http: $batches+1; \
		log_file: $logFile; \
		log_disable: False:C215; \
		n_gpu_layers: $n_gpu_layers}
	
	$embeddings:=cs:C1710.event.huggingface.new($folder; $URL; $path)
	$huggingfaces:=cs:C1710.event.huggingfaces.new([$embeddings])
	$llama:=cs:C1710.llama.llama.new($port; $huggingfaces; $homeFolder; $options; $event)
	
End if 

If (False:C215)
	
	$folder:=$homeFolder.folder("granite-embedding-english-r2")
	$path:="granite-embedding-english-r2-Q8_0.gguf"
	$URL:="keisuke-miyako/granite-embedding-english-r2-gguf-q8_0"
	
	$pooling:="cls"
	
	$logFile:=$folder.file("llama.log")
	$folder.create()
	If (Not:C34($logFile.exists))
		$logFile.setContent(4D:C1709.Blob.new())
	End if 
	
	$port:=Storage:C1525.ports.graniteEn
	$options:={\
		embeddings: True:C214; \
		pooling: $pooling; \
		ctx_size: $max_position_embeddings*$batches; \
		batch_size: $batch_size*$batches; \
		ubatch_size: $ubatch_size; \
		parallel: $batches; \
		threads: $threads; \
		threads_batch: $threads_batch; \
		threads_http: $batches+1; \
		log_file: $logFile; \
		log_disable: False:C215; \
		n_gpu_layers: $n_gpu_layers}
	
	$embeddings:=cs:C1710.event.huggingface.new($folder; $URL; $path)
	$huggingfaces:=cs:C1710.event.huggingfaces.new([$embeddings])
	$llama:=cs:C1710.llama.llama.new($port; $huggingfaces; $homeFolder; $options; $event)
	
End if 

If (False:C215)
	
	$folder:=$homeFolder.folder("nomic-embed-text-v1.5")
	$path:="nomic-embed-text-v1.5-Q8_0.gguf"
	$URL:="keisuke-miyako/nomic-embed-text-v1.5-gguf-q8_0"
	
	$pooling:="mean"
	
	$logFile:=$folder.file("llama.log")
	$folder.create()
	If (Not:C34($logFile.exists))
		$logFile.setContent(4D:C1709.Blob.new())
	End if 
	
	$port:=Storage:C1525.ports.nomicEn
	$options:={\
		embeddings: True:C214; \
		pooling: $pooling; \
		ctx_size: $max_position_embeddings*$batches; \
		batch_size: $batch_size*$batches; \
		ubatch_size: $ubatch_size; \
		parallel: $batches; \
		threads: $threads; \
		threads_batch: $threads_batch; \
		threads_http: $batches+1; \
		log_file: $logFile; \
		log_disable: False:C215; \
		n_gpu_layers: $n_gpu_layers}
	
	$embeddings:=cs:C1710.event.huggingface.new($folder; $URL; $path)
	$huggingfaces:=cs:C1710.event.huggingfaces.new([$embeddings])
	$llama:=cs:C1710.llama.llama.new($port; $huggingfaces; $homeFolder; $options; $event)
	
End if 

If (False:C215)
	
	$folder:=$homeFolder.folder("e5-base-v2")
	$path:="e5-base-v2-Q8_0.gguf"
	$URL:="keisuke-miyako/e5-base-v2-gguf-q8_0"
	
	$pooling:="mean"
	
	$logFile:=$folder.file("llama.log")
	$folder.create()
	If (Not:C34($logFile.exists))
		$logFile.setContent(4D:C1709.Blob.new())
	End if 
	
	$port:=Storage:C1525.ports.e5En
	$options:={\
		embeddings: True:C214; \
		pooling: $pooling; \
		ctx_size: $max_position_embeddings*$batches; \
		batch_size: $batch_size*$batches; \
		ubatch_size: $ubatch_size; \
		parallel: $batches; \
		threads: $threads; \
		threads_batch: $threads_batch; \
		threads_http: $batches+1; \
		log_file: $logFile; \
		log_disable: False:C215; \
		n_gpu_layers: $n_gpu_layers}
	
	$embeddings:=cs:C1710.event.huggingface.new($folder; $URL; $path)
	$huggingfaces:=cs:C1710.event.huggingfaces.new([$embeddings])
	$llama:=cs:C1710.llama.llama.new($port; $huggingfaces; $homeFolder; $options; $event)
	
End if 

If (False:C215)
	
	$folder:=$homeFolder.folder("snowflake-arctic-embed-l-v2.0")
	$path:="snowflake-arctic-embed-l-v2.0-Q8_0.gguf"
	$URL:="keisuke-miyako/snowflake-arctic-embed-l-v2.0-gguf"
	
	$pooling:="cls"
	
	$logFile:=$folder.file("llama.log")
	$folder.create()
	If (Not:C34($logFile.exists))
		$logFile.setContent(4D:C1709.Blob.new())
	End if 
	
	$port:=Storage:C1525.ports.arctic
	$options:={\
		embeddings: True:C214; \
		pooling: $pooling; \
		ctx_size: $max_position_embeddings*$batches; \
		batch_size: $batch_size*$batches; \
		ubatch_size: $ubatch_size; \
		parallel: $batches; \
		threads: $threads; \
		threads_batch: $threads_batch; \
		threads_http: $batches+1; \
		log_file: $logFile; \
		log_disable: False:C215; \
		n_gpu_layers: $n_gpu_layers}
	
	$embeddings:=cs:C1710.event.huggingface.new($folder; $URL; $path)
	$huggingfaces:=cs:C1710.event.huggingfaces.new([$embeddings])
	$llama:=cs:C1710.llama.llama.new($port; $huggingfaces; $homeFolder; $options; $event)
	
End if 

If (False:C215)
	
	$folder:=$homeFolder.folder("gte-modernbert")
	$path:="gte-modernbert-base-Q8_0.gguf"
	$URL:="keisuke-miyako/gte-modernbert-base-gguf"
	
	$pooling:="mean"
	
	$logFile:=$folder.file("llama.log")
	$folder.create()
	If (Not:C34($logFile.exists))
		$logFile.setContent(4D:C1709.Blob.new())
	End if 
	
	$port:=Storage:C1525.ports.gte
	$options:={\
		embeddings: True:C214; \
		pooling: $pooling; \
		ctx_size: $max_position_embeddings*$batches; \
		batch_size: $batch_size*$batches; \
		ubatch_size: $ubatch_size; \
		parallel: $batches; \
		threads: $threads; \
		threads_batch: $threads_batch; \
		threads_http: $batches+1; \
		log_file: $logFile; \
		log_disable: False:C215; \
		n_gpu_layers: $n_gpu_layers}
	
	$embeddings:=cs:C1710.event.huggingface.new($folder; $URL; $path)
	$huggingfaces:=cs:C1710.event.huggingfaces.new([$embeddings])
	$llama:=cs:C1710.llama.llama.new($port; $huggingfaces; $homeFolder; $options; $event)
	
End if 

If (False:C215)
	
	$folder:=$homeFolder.folder("snowflake-arctic-embed-l")
	$path:="snowflake-arctic-embed-l-Q8_0.gguf"
	$URL:="keisuke-miyako/snowflake-arctic-embed-l-gguf"
	
	$pooling:="mean"
	
	$logFile:=$folder.file("llama.log")
	$folder.create()
	If (Not:C34($logFile.exists))
		$logFile.setContent(4D:C1709.Blob.new())
	End if 
	
	$port:=Storage:C1525.ports.arcticEn
	$options:={\
		embeddings: True:C214; \
		pooling: $pooling; \
		ctx_size: $max_position_embeddings*$batches; \
		batch_size: $batch_size*$batches; \
		ubatch_size: $ubatch_size; \
		parallel: $batches; \
		threads: $threads; \
		threads_batch: $threads_batch; \
		threads_http: $batches+1; \
		log_file: $logFile; \
		log_disable: False:C215; \
		n_gpu_layers: $n_gpu_layers}
	
	$embeddings:=cs:C1710.event.huggingface.new($folder; $URL; $path)
	$huggingfaces:=cs:C1710.event.huggingfaces.new([$embeddings])
	$llama:=cs:C1710.llama.llama.new($port; $huggingfaces; $homeFolder; $options; $event)
	
End if 
