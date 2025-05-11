package elk.net;

import haxe.MainLoop;
import hx.ws.WebSocket;
import hx.ws.Types;
#if (sys || hxnodejs)
import hx.ws.WebSocketServer;
import hx.ws.WebSocketHandler;
import hx.ws.WebSocketSecureServer;
import hx.ws.SocketImpl;
import hx.ws.HttpResponse;
import hx.ws.HttpRequest;
import hx.ws.Types;
#end
#if !hxbit
#error "Using SocketHost requires compiling with -lib hxbit"
#end
import hxbit.NetworkHost;

class WebSocketClient extends NetworkClient {
	var socket : WebSocket;

	public function new(host, s) {
		super(host);
		this.socket = s;
		if( s != null ) s.onmessage = function(message) {
			switch (message) {
				case BytesMessage(content):
					var bytes = content.readAllAvailableBytes();
					haxe.MainLoop.runInMainThread(() -> processMessagesData(bytes, 0, bytes.length));
				case StrMessage(content):
			}
		}
	}

	override function error(msg : String) {
		socket.close();
		super.error(msg);
	}

	override function send(bytes : haxe.io.Bytes) {
		if( socket == null || socket.state == Closed ) return;
		#if js
		var data = bytes.getData();
		if( data.byteLength != bytes.length ) {
			data = data.slice(0, bytes.length);
		}
		socket.send(data);
		return;
		#end
		socket.send(bytes);
	}

	override function stop() {
		super.stop();
		if( socket != null ) {
			socket.close();
			socket = null;
		}
	}
}

private class WebSocketHostCommon extends NetworkHost {
	public var connected(default, null) = false;
	public var enableSound : Bool = true;

	var web_socket : hx.ws.WebSocket;
	var on_disconnect : Void -> Void = null;

	public function new() {
		super();
		isAuth = false;
	}

	function close() {
		if( connected && on_disconnect != null ) {
			on_disconnect();
		}

		connected = false;

		if( web_socket != null ) {
			trace('closed socket.');
			// If mid connection, socket might not close correctly.
			// in this case, close the socket as soon as it connects.
			web_socket.onopen = web_socket.close;
			var sock = web_socket;
			web_socket = null;
			sock.close();
		}
	}

	override public function dispose() {
		super.dispose();
		close();
	}

	public function connect(address : String, ?protocols : Array<String>, ?onConnect : Bool -> Void, ?onDisconnect : Void -> Void) {
		close();
		on_disconnect = onDisconnect;

		isAuth = false;
		web_socket = new hx.ws.WebSocket(address, false, protocols);

		self = new WebSocketClient(this, web_socket);

		var successfully_connected = false;

		web_socket.onerror = function(msg) {
			if( !connected ) {
				web_socket.onerror = function(_) {};
				if( onConnect != null ) onConnect(false);
			} else throw msg;
		};

		web_socket.onopen = function() {
			web_socket.onerror = null;
			connected = true;
			successfully_connected = true;
			if( StringTools.contains(address, "127.0.0.1") ) enableSound = false;
			clients = [self];
			if( onConnect != null ) onConnect(true);
		}

		web_socket.onclose = function() {
			if( !successfully_connected && onConnect != null ) {
				onConnect(false);
			}
			close();
		}

		web_socket.open();
	}

	public function offlineServer() {
		close();
		self = new WebSocketClient(this, null);
		isAuth = true;
	}
}

#if (sys || hxnodejs)
class WebSocketHandlerClient extends NetworkClient {
	public var socket : WebSocketHandler;

	public function new(host, s) {
		super(host);
		this.socket = s;
		if( s != null ) {
			s.onmessage = function(message) {
				try {
					switch (message) {
						case BytesMessage(content):
							var bytes = content.readAllAvailableBytes();
							haxe.MainLoop.runInMainThread(() -> processMessagesData(bytes, 0, bytes.length));

						case StrMessage(content):
					}
				} catch (e) {
					trace(e);
					trace(haxe.CallStack.toString(haxe.CallStack.callStack()));
					stop();
				}
			}
		}
	}

	override function error(msg : String) {
		if( socket != null ) socket.close();
		super.error(msg);
	}

	override function send(bytes : haxe.io.Bytes) {
		if( socket == null || socket.state == Closed ) return;
		socket.send(bytes);
	}

	override public function stop() {
		super.stop();
		if( socket != null ) {
			socket.close();
		}
	}
}

class CustomHandler extends WebSocketHandler {
	public function new(s) {
		super(s);
		this.validateHandshake = WebSocketHost.handleRequest;
	}
}

class WebSocketHost extends WebSocketHostCommon {
	var server : WebSocketServer<CustomHandler>;

	static public var handleRequest : (handler : hx.ws.Handler, req : HttpRequest, res : HttpResponse, callback : (HttpResponse) -> Void) -> Void = null;

	override function close() {
		super.close();
		if( server != null ) {
			server.stop();
			server = null;
		}
	}

	public function wait(host : String, port : Int, ?onConnected : NetworkClient -> Void, ?onDisconnected : NetworkClient -> Void) {
		close();
		isAuth = false;
		self = new WebSocketHandlerClient(this, null);
		server = new WebSocketServer(host, port, 100);

		server.onClientAdded = (client) -> {
			var c = new WebSocketHandlerClient(this, client);
			client.onopen = () -> {
				pendingClients.push(c);
				if( onConnected != null ) {
					MainLoop.runInMainThread(() -> onConnected(c));
				}
				client.onclose = () -> {
					c.stop();
					if( onDisconnected != null ) {
						MainLoop.runInMainThread(() -> onDisconnected(c));
					}
					client.onclose = null;
				}
			}
			client.onerror = function(err) {
				trace(err);
				// trace(haxe.CallStack.toString(haxe.CallStack.callStack()));
			}
		}

		server.start();
		isAuth = true;
	}
}
#else
class WebSocketHost extends WebSocketHostCommon {
	public function wait(host : String, port : Int, ?onConnected : NetworkClient -> Void) {
		throw "Can't host websocket server in browser.";
	}
}
#end
