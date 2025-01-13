package elk.net;

import hx.ws.WebSocket;
import hx.ws.Types;
#if (sys || hxnodejs)
import hx.ws.WebSocketServer;
import hx.ws.WebSocketHandler;
import hx.ws.WebSocketSecureServer;
#end
#if !hxbit
#error "Using SocketHost requires compiling with -lib hxbit"
#end
import hxbit.NetworkHost;

class WebSocketClient extends NetworkClient {
	var socket:WebSocket;

	public function new(host, s) {
		super(host);
		this.socket = s;
		if (s != null)
			s.onmessage = function(message) {
				switch (message) {
					case BytesMessage(content):
						var bytes = content.readAllAvailableBytes();
						processMessagesData(bytes, 0, bytes.length);
					case StrMessage(content):
				}
			}
	}

	override function error(msg:String) {
		socket.close();
		super.error(msg);
	}

	override function send(bytes:haxe.io.Bytes) {
		if (socket == null || socket.state == Closed)
			return;
		#if js
		var data = bytes.getData();
		if (data.byteLength != bytes.length) {
			data = data.slice(0, bytes.length);
		}
		socket.send(data);
		return;
		#end
		socket.send(bytes);
	}

	override function stop() {
		super.stop();
		if (socket != null) {
			socket.close();
			socket = null;
		}
	}
}

private class WebSocketHostCommon extends NetworkHost {
	public var connected(default, null) = false;
	public var enableSound:Bool = true;

	var web_socket:hx.ws.WebSocket;
	var on_disconnect:Void->Void = null;

	public function new() {
		super();
		MultiplayerHandler.instance.host = this;
		isAuth = false;
	}

	function close() {
		if (connected && on_disconnect != null) {
			#if (target.threaded)
			haxe.MainLoop.runInMainThread(() -> {
			#end
				on_disconnect();
			#if (target.threaded)
			});
			#end
		}

		connected = false;

		if (web_socket != null) {
			trace('closed socket.');
			// If mid connection, socket might not close correctly.
			// in this case, close the socket as soon as it connects.
			web_socket.onopen = web_socket.close;
			web_socket.close();
			web_socket = null;
		}

		MultiplayerHandler.instance.reset();
	}

	override function dispose() {
		super.dispose();
		close();
	}

	public function connect(address:String, ?protocols:Array<String>, ?onConnect:Bool->Void, ?onDisconnect:Void->Void) {
		close();
		on_disconnect = onDisconnect;

		isAuth = false;
		web_socket = new hx.ws.WebSocket(address, false, protocols);

		self = new WebSocketClient(this, web_socket);

		web_socket.onerror = function(msg) {
			if (!connected) {
				web_socket.onerror = function(_) {};
				if (onConnect != null)
					onConnect(false);
			} else
				throw msg;
		};

		web_socket.onopen = function() {
			web_socket.onerror = null;
			connected = true;
			if (StringTools.contains(address, "127.0.0.1"))
				enableSound = false;
			clients = [self];
			if (onConnect != null)
				onConnect(true);
		}

		web_socket.onclose = function() {
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
	var socket:WebSocketHandler;

	public function new(host, s) {
		super(host);
		this.socket = s;
		if (s != null) {
			s.onmessage = function(message) {
				try {
					switch (message) {
						case BytesMessage(content):
							var bytes = content.readAllAvailableBytes();
							processMessagesData(bytes, 0, bytes.length);

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

	override function error(msg:String) {
		socket.close();
		super.error(msg);
	}

	override function send(bytes:haxe.io.Bytes) {
		if (socket == null || socket.state == Closed)
			return;
		socket.send(bytes);
	}

	override public function stop() {
		super.stop();
		if (socket != null) {
			socket.close();
		}
	}
}

class WebSocketHost extends WebSocketHostCommon {
	var server:WebSocketServer<elk.newgrounds.NGWebSocketHandler>;

	override function close() {
		super.close();
		if (server != null) {
			server.stop();
			server = null;
		}
	}

	public function wait(host:String, port:Int, ?onConnected:NetworkClient->Void, ?onDisconnected:NetworkClient->Void, ?use_tls:Bool = false) {
		close();
		isAuth = false;
		self = new WebSocketHandlerClient(this, null);
		if (!use_tls) {
			server = new WebSocketServer(host, port, 100);
		} else {
			var host_address = Sys.getEnv("HOST_ADDRESS");

			var cert_path = '/etc/letsencrypt/live/$host_address/cert.pem';
			var key_path = '/etc/letsencrypt/live/$host_address/privkey.pem';
			var full_chain_path = '/etc/letsencrypt/live/$host_address/fullchain.pem';
			var cert = sys.ssl.Certificate.fromString(sys.io.File.getContent(cert_path));
			// var full_chain = sys.ssl.Certificate.fromString(sys.io.File.getContent(full_chain_path));
			var full_chain = sys.ssl.Certificate.loadDefaults();
			var key = sys.ssl.Key.readPEM(sys.io.File.getContent(key_path), false);
			var server = new WebSocketSecureServer<elk.newgrounds.NGWebSocketHandler>(host, port, cert, key, full_chain, 100);
			this.server = server;
		}

		server.onClientAdded = (client) -> {
			var c = new WebSocketHandlerClient(this, client);
			client.onopen = () -> {
				pendingClients.push(c);
				if (onConnected != null)
					onConnected(c);
				client.onclose = () -> {
					c.stop();
					if (onDisconnected != null) {
						onDisconnected(c);
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
	public function wait(host:String, port:Int, ?onConnected:NetworkClient->Void, ?use_tls:Bool = false) {
		throw "Can't host websocket server in browser.";
	}
}
#end
