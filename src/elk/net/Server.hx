package elk.net;

import elk.net.MultiplayerClient;

@:generic
class Server<T:haxe.Constraints.Constructible<(hxbit.NetworkHost.NetworkClient, hxbit.NetworkHost) -> Void> & MultiplayerClient> {
	var running = false;

	public var on_message:(T, Dynamic) -> Void;
	public var on_connected:(T) -> Void;
	public var on_disconnected:(T) -> Void;

	var max_users = 100;
	var bind_address = '0.0.0.0';
	var bind_port = 9999;

	var host:elk.net.WebSocketHost = null;

	public var clients:Array<T> = [];

	public function new(address = '0.0.0.0', port = 9999, max_users = 100) {
		this.bind_address = address;
		this.bind_port = port;
		this.max_users = max_users;
		start();
	}

	public function stop() {
		if (!running)
			return;
		running = false;
		host.dispose();
		host = null;
	}

	public function start() {
		stop();

		host = new elk.net.WebSocketHost();

		host.wait(bind_address, bind_port, (client) -> {
			var user = new T(client, host);
			trace('server: client connect: ${user.uid}');
			client.sendMessage('uid:${user.uid}');
			client.sync();
			clients.push(user);
			if (on_connected != null)
				on_connected(user);
		}, (client) -> {
			for (c in clients) {
				if (c.client == client) {
					clients.remove(c);
					trace('server: client disconnect: ${c.uid}, $clients');
					@:privateAccess
					c.disconnect();
					if (on_disconnected != null)
						on_disconnected(c);
					break;
				}
			}
		});

		host.onMessage = (client:hxbit.NetworkHost.NetworkClient, message:Dynamic) -> {
			if (on_message == null)
				return;
			if (client == null)
				on_message(null, message);

			var mp_client = get_multiplayer_client(client);
			if (mp_client == null)
				throw('Could not find client for message: $message');

			on_message(mp_client, message);
		}

		host.onUnregister = (e) -> {
			trace('unregistered');
			trace(e);
		}

		host.makeAlive();
		running = true;

		Sys.println('Listening on $bind_address:$bind_port');
	}

	function get_multiplayer_client(c:hxbit.NetworkHost.NetworkClient) {
		for (client in clients)
			if (client.client == c)
				return client;

		return null;
	}

	var elapsed = 0.0;
	var last_time = 0.0;

	public function update(dt:Float) {
		trace('$elapsed, $dt');
		elapsed += dt;
		if (running && host != null && elapsed > 0.5) {
			trace("fuls");
			elapsed = 0.0;
			host.flush();
		}
	}
}
