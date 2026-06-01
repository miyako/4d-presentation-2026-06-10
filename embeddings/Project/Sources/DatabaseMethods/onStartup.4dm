var $llama : cs:C1710.llama.llama
var $huggingfaces : cs:C1710.event.huggingfaces
var $embeddings; $rerank : cs:C1710.event.huggingface
var $homeFolder : 4D:C1709.Folder

var $file : 4D:C1709.File
var $URL : Text
var $port : Integer

var $event : cs:C1710.event.event
$event:=cs:C1710.event.event.new()

/*
これらのコールバックはプリエンプティブスレッドで実行されます。
*/

$event.onError:=Formula:C1597(OnModelDownloaded)
$event.onSuccess:=Formula:C1597(OnModelDownloaded)
$event.onData:=Formula:C1597(LOG EVENT:C667(Into 4D debug message:K38:5; This:C1470.file.fullName+":"+String:C10((This:C1470.range.end/This:C1470.range.length)*100; "###.00%")))
$event.onResponse:=Formula:C1597(LOG EVENT:C667(Into 4D debug message:K38:5; This:C1470.file.fullName+":download complete"))
$event.onTerminate:=Formula:C1597(LOG EVENT:C667(Into 4D debug message:K38:5; (["process"; $1.pid; "terminated!"].join(" "))))

$homeFolder:=Folder:C1567(fk home folder:K87:24).folder(".GGUF")
var $max_position_embeddings; $batch_size; $parallel : Integer
var $ubatch_size; $n_gpu_layers; $threads; $threads_batch; $batches : Integer
var $ctx_size; $temp; $min_p; $top_k; $top_p; $repeat_penalty; $presence_penalty : Integer

var $folder : 4D:C1709.Folder
var $logFile : 4D:C1709.File
var $path; $pooling : Text
var $options : Object

/*
* 埋め込みモデル
 */

$folder:=$homeFolder.folder("embeddinggemma-300m")
$path:="embeddinggemma-300m-Q8_0.gguf"
$URL:="keisuke-miyako/embeddinggemma-300m-gguf-q8_0"

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

$max_position_embeddings:=1024
$pooling:="mean"
$batch_size:=$max_position_embeddings
$ubatch_size:=$max_position_embeddings
$n_gpu_layers:=-1

$batches:=2
$threads:=2
$threads_batch:=2

$logFile:=$folder.file("llama.log")
$folder.create()
If (Not:C34($logFile.exists))
	$logFile.setContent(4D:C1709.Blob.new())
End if 

$port:=8888
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
//$llama:=cs.llama.llama.new($port; $huggingfaces; $homeFolder; $options; $event)