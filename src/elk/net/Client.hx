package elk.net;

#if use_websockets
typedef Host = WebSocketHost;
#else
typedef Host = SocketHost;
#end

class Client {
	public var host : Host;

	public dynamic function onConnectionFailure() {}

	public dynamic function onConnected() {}

	public dynamic function onDisconnected() {}

	public dynamic function onMessage(client : hxbit.NetworkHost.NetworkClient, message : Dynamic) {}

	public var websocketProtocols : Array<String> = null;
	public var useTLS = false;

	public function new() {}

	public function dispose() {
		if( host == null ) return;
		haxe.MainLoop.runInMainThread(onDisconnected);
		host.dispose();
		host = null;
	}

	public function connect(address : String) {
		if( host != null ) {
			dispose();
		}

		#if (target.threaded)
		haxe.MainLoop.addThread(() -> {
		#end
			try {
				if( host == null ) {
					host = new Host();
				}

				#if hxbit_visibility
				host.lateRegistration = true;
				#end

				#if (!release && !js)
				host.setLogger(t -> {
					// trace(t);
				});
				#end

				#if use_websockets
				var protocol = useTLS ? 'wss' : 'ws';
				var addr = '$protocol://$address';
				host.connect(addr, websocketProtocols, (connected : Bool) -> {
				#else
				host.connect(address, port, (connected : Bool) -> {
				#end
					if( !connected ) {
						onConnectionFailure();
						return;
					}

					haxe.MainLoop.runInMainThread(onConnected);
					trace('connected to server.');
				},
				function() {
					haxe.MainLoop.runInMainThread(onDisconnected);
					trace('disconnected from server.');
				});

				host.onMessage = (client : hxbit.NetworkHost.NetworkClient, m : Dynamic) -> {
					onMessage(client, m);
				}
			} catch (e)
			{
				trace(e);
			}
		#if (target.threaded)
		});
		#end
	}

	public function flush() {
		if( host == null ) return;
		host.flush();
		host.makeAlive();
	}
}
