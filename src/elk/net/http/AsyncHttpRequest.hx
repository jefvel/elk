package elk.net.http;

class AsyncHttpRequest {
	#if (target.threaded)
	static var pool: sys.thread.FixedThreadPool = new sys.thread.FixedThreadPool(10);
	#end

	public function new() {}

	function start_job() {}
}
