var $homeFolder; $folder : 4D:C1709.Folder
$homeFolder:=Folder:C1567(fk home folder:K87:24).folder(".GGUF")
$folder:=$homeFolder.folder("bge-m3")
var $path : Text

Case of 
	: (File:C1566(Data file:C490; fk platform path:K87:2).name="original-bge-m3-data")
		$path:="bge-m3-Q8_0.gguf"
	: (File:C1566(Data file:C490; fk platform path:K87:2).name="finetuned-r1-bge-m3-data")
		$path:="bge-m3-doc-r1-q8_0.gguf"
	Else 
		$path:="bge-m3-doc-r1-q8_0.gguf"
End case 

var $modelFile : 4D:C1709.File
$modelFile:=$folder.file($path)
ASSERT:C1129($modelFile.exists)
Extract SET OPTION(Extract Option Tokenizer File; $modelFile)

Use (Storage:C1525)
	Storage:C1525.port:=New shared object:C1526("embeddings"; 7001; "reranker"; 7002)
End use 

var $llama : cs:C1710.llama.llama
var $huggingfaces : cs:C1710.event.huggingfaces
var $embeddings; $rerank : cs:C1710.event.huggingface

var $file : 4D:C1709.File
var $URL : Text
var $port : Integer

var $event : cs:C1710.event.event
$event:=cs:C1710.event.event.new()

//$event.onError:=Formula(OnModelDownloaded)
//$event.onSuccess:=Formula(OnModelDownloaded)
//$event.onData:=Formula(LOG EVENT(Into 4D debug message; This.file.fullName+":"+String((This.range.end/This.range.length)*100; "###.00%")))
//$event.onResponse:=Formula(LOG EVENT(Into 4D debug message; This.file.fullName+":download complete"))
//$event.onTerminate:=Formula(LOG EVENT(Into 4D debug message; (["process"; $1.pid; "terminated!"].join(" "))))

var $max_position_embeddings; $batch_size; $parallel; $threads; $batches : Integer

$URL:="keisuke-miyako/bge-m3-gguf-q8_0"
$URL:="keisuke-miyako/bge-m3-doc-r1-gguf"

var $pooling; $cache_type_k; $cache_type_v : Text
var $ubatch_size; $n_gpu_layers : Integer
var $threads_batch : Integer
var $options : Object

$pooling:="cls"
$ubatch_size:=512  //max_position_embeddings=8194, but for better granularity
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
embeddings: True:C214; \
pooling: $pooling; \
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
$ubatch_size:=1024  //ettin uses more tokens than BGE M3
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
pooling: $pooling; \
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