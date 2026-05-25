Use (Storage:C1525)
	Storage:C1525.port:=New shared object:C1526("embeddings"; 9080; "reranker"; 9081)
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
var $max_position_embeddings; $batch_size; $parallel; $threads; $batches : Integer

//$folder:=$homeFolder.folder("bge-m3")
//$path:="bge-m3-Q8_0.gguf"
//$URL:="keisuke-miyako/bge-m3-gguf-q8_0"

$folder:=$homeFolder.folder("bge-m3-legal-euro")
$path:="bge-m3-legal-q8_0.gguf"
$URL:="keisuke-miyako/bge-m3-legal-euro-r15-gguf"

$pooling:="cls"
$ubatch_size:=1024  //max_position_embeddings=8194, but for better granularity
$n_gpu_layers:=-1
$cache_type_k:="f16"
$cache_type_v:="f16"

$batches:=16  //may increase with P cores
$threads:=$batches  //input; tokenisers
$threads_batch:=1  //output; GPU does the heavy lifting

var $logFile : 4D:C1709.File
$logFile:=$folder.file("llama.log")
$folder.create()
If (Not:C34($logFile.exists))
	$logFile.setContent(4D:C1709.Blob.new())
End if 

$port:=Storage:C1525.port.embeddings
$options:={\
embeddings: True:C214; pooling: $pooling; \
ctx_size: $ubatch_size*$batches; \
batch_size: $ubatch_size*$batches; \
ubatch_size: $ubatch_size; \
parallel: $batches; \
threads: $threads; \
threads_batch: $threads_batch; \
threads_http: $batches+1; \
log_file: $logFile; \
log_disable: False:C215; \
n_gpu_layers: $n_gpu_layers; \
cache_type_k: $cache_type_k; \
cache_type_v: $cache_type_v}

$embeddings:=cs:C1710.event.huggingface.new($folder; $URL; $path)
$huggingfaces:=cs:C1710.event.huggingfaces.new([$embeddings])
$llama:=cs:C1710.llama.llama.new($port; $huggingfaces; $homeFolder; $options; $event)

$folder:=$homeFolder.folder("ettin-reranker")
$path:="ettin-reranker-1b-v1-Q8_0.gguf"
$URL:="keisuke-miyako/ettin-reranker-v1-gguf"

$pooling:="rank"
$ubatch_size:=2048  //ettin uses more tokens than wen
$n_gpu_layers:=-1
$cache_type_k:="f16"
$cache_type_v:="f16"

$logFile:=$folder.file("llama.log")
$folder.create()
If (Not:C34($logFile.exists))
	$logFile.setContent(4D:C1709.Blob.new())
End if 

$batches:=10  //may increase with P cores
$threads:=$batches  //input; tokenisers
$threads_batch:=1  //output; GPU does the heavy lifting

$port:=Storage:C1525.port.reranker
$options:={\
reranking: True:C214; \
ctx_size: $ubatch_size*$batches; \
batch_size: $ubatch_size*$batches; \
ubatch_size: $ubatch_size; \
parallel: $batches; \
threads: $threads; \
threads_batch: $threads_batch; \
threads_http: $batches+1; \
log_file: $logFile; \
log_disable: False:C215; \
n_gpu_layers: $n_gpu_layers; \
cache_type_k: $cache_type_k; \
cache_type_v: $cache_type_v}

$rerank:=cs:C1710.event.huggingface.new($folder; $URL; $path)
$huggingfaces:=cs:C1710.event.huggingfaces.new([$rerank])
$llama:=cs:C1710.llama.llama.new($port; $huggingfaces; $homeFolder; $options; $event)