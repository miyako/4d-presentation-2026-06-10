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

var $iniFile : 4D:C1709.File
var $ini : Collection

$ini:=[]
$ini.push("version = 1")

$ini.push("[embeddinggemma]")
$ini.push("model = "+$homeFolder.file("embeddinggemma-300m/embeddinggemma-300m-Q8_0.gguf").path)
$ini.push("pooling = mean")

$ini.push("[ettin-encoder]")
$ini.push("model = "+$homeFolder.file("ettin-encoder/ettin-encoder-400m-Q8_0.gguf").path)
$ini.push("pooling = mean")

$ini.push("[nomic-embed-text-v2-moe]")
$ini.push("model = "+$homeFolder.file("nomic-embed-text-v2-moe/nomic-embed-text-v2-moe-Q8_0.gguf").path)
$ini.push("pooling = mean")

$ini.push("[nomic-embed-text-v1.5]")
$ini.push("model = "+$homeFolder.file("nomic-embed-text-v1.5/nomic-embed-text-v1.5-Q8_0.gguf").path)
$ini.push("pooling = mean")

$ini.push("[multilingual-e5-base]")
$ini.push("model = "+$homeFolder.file("multilingual-e5-base/multilingual-e5-base-Q8_0.gguf").path)
$ini.push("pooling = mean")

$ini.push("[e5-base-v2]")
$ini.push("model = "+$homeFolder.file("e5-base-v2/e5-base-v2-Q8_0.gguf").path)
$ini.push("pooling = mean")

//pooling: last-token

$ini.push("[Qwen3-Embedding-0.6B]")
$ini.push("model = "+$homeFolder.file("Qwen3-Embedding-0.6B/Qwen3-Embedding-0.6B-Q8_0.gguf").path)
$ini.push("pooling = last")

//pooling: CLS

$ini.push("[bge-m3]")
$ini.push("model = "+$homeFolder.file("bge-m3/bge-m3-Q8_0.gguf").path)
$ini.push("pooling = cls")

$ini.push("[granite-embedding-multilingual-r2]")
$ini.push("model = "+$homeFolder.file("granite-embedding-multilingual-r2/granite-embedding-311m-multilingual-r2-Q8_0.gguf").path)
$ini.push("pooling = cls")

$ini.push("[granite-embedding-english-r2]")
$ini.push("model = "+$homeFolder.file("granite-embedding-english-r2/granite-embedding-english-r2-Q8_0.gguf").path)
$ini.push("pooling = cls")

$ini.push("[gte-modernbert]")
$ini.push("model = "+$homeFolder.file("gte-modernbert/gte-modernbert-base-Q8_0.gguf").path)
$ini.push("pooling = cls")  //https://huggingface.co/Alibaba-NLP/gte-modernbert-base/blob/main/1_Pooling/config.json

$ini.push("[snowflake-arctic-embed-l-v2.0]")
$ini.push("model = "+$homeFolder.file("snowflake-arctic-embed-l-v2.0/snowflake-arctic-embed-l-v2.0-Q8_0.gguf").path)
$ini.push("pooling = cls")  //https://huggingface.co/Snowflake/snowflake-arctic-embed-l-v2.0/blob/main/1_Pooling/config.json

$ini.push("[snowflake-arctic-embed-l]")
$ini.push("model = "+$homeFolder.file("snowflake-arctic-embed-l/snowflake-arctic-embed-l-Q8_0.gguf").path)
$ini.push("pooling = cls")

$port:=8888
$folder:=$homeFolder.folder("llama-"+String:C10($port))

$iniFile:=$folder.file("models.ini")
$iniFile.setText($ini.join("\n"))

$options:={\
embeddings: True:C214; \
models_preset: $iniFile; \
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

$llama:=cs:C1710.llama.llama.new($port; Null:C1517; $homeFolder; $options; $event)
