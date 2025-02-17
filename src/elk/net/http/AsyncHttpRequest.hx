package elk.net.http;

import sys.net.Socket;
import haxe.io.BytesOutput;
import sys.thread.Thread;
import haxe.io.Bytes;
import haxe.Http;

enum abstract HttpMethod(String) from String to String {
	var GET = "GET";
	var POST = "POST";
}

typedef FetchOptions = {
	method : HttpMethod,
	body : String,
}

class AsyncHttpRequest {
	#if (target.threaded)
	static var pool : sys.thread.FixedThreadPool = new sys.thread.FixedThreadPool(10);
	#end

	var request : Http;

	public var statusCode = 0;
	public var method : HttpMethod = GET;
	public var url : String = null;

	var requestBody : Bytes = null;

	public function new(url : String, method = "GET", data : Bytes = null) {
		this.url = url;
		this.method = method;
		this.requestBody = data;
	}

	public function run() {
		#if (target.threaded)
		pool.run(process);
		#else
		process();
		#end
	}

	function process() {
		request = new Http(url);

		if( requestBody != null ) {
			request.setPostBytes(requestBody);
		}

		request.onStatus = (s) -> statusCode = s;

		request.onBytes = (b) -> haxe.MainLoop.runInMainThread(() -> onData(b, this));
		request.onData = (b) -> haxe.MainLoop.runInMainThread(() -> onResponse(b, this));
		request.onError = (b) -> haxe.MainLoop.runInMainThread(() -> onError(b, this));

		trace('reqesting');
		request.request(method == POST);
	}

	public static function fetch(url : String, options : FetchOptions) {
		var req = new AsyncHttpRequest(url, options?.method ?? GET);
		req.run();
	}

	public dynamic function onData(bytes : Bytes, request : AsyncHttpRequest) {}

	public dynamic function onResponse(text : String, request : AsyncHttpRequest) {}

	public dynamic function onError(error : String, request : AsyncHttpRequest) {}
}
