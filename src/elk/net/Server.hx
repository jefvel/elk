package elk.net;

import elk.net.MultiplayerClient;

@:generic
class Server<T:haxe.Constraints.Constructible<(hxbit.NetworkHost.NetworkClient, hxbit.NetworkHost) -> Void> & MultiplayerClient> {
	var running = false;

	public var on_message: (T, Dynamic) -> Void;
	public var on_client_connected: (T) -> Void;
	public var on_client_disconnected: (T) -> Void;

	var max_users = 100;
	var bind_address = '0.0.0.0';
	var bind_port = 9999;

	public var host: elk.net.WebSocketHost = null;

	public var clients: Array<T> = [];

	public function new(address = '0.0.0.0', port = 9999, max_users = 100) {
		this.bind_address = address;
		this.bind_port = port;
		this.max_users = max_users;
		start();
	}

	public function stop() {
		if (!running) return;
		running = false;
		host.dispose();
		host = null;
	}

	public function start() {
		stop();

		var use_tls = Sys.getEnv("USE_TLS") == "true";

		host = new elk.net.WebSocketHost();
		host.setLogger((t) -> trace(t));

		host.setStats(new hxbit.NetworkStats());

		host.wait(bind_address, bind_port, (client) -> {
			trace('clecl');
			var user = new T(client, host);
			trace('server: client connect: ${user.uid}');
			client.sendMessage('uid:${user.uid}');
			client.sync();
			clients.push(user);
			if (on_client_connected != null) on_client_connected(user);
		}, (client) -> {
			for (c in clients) {
				if (c.client == client) {
					clients.remove(c);
					trace('server: client disconnect: ${c.uid}, $clients');
					c.enableReplication = false;
					MultiplayerHandler.instance.on_unregister(c);
					if (on_client_disconnected != null) on_client_disconnected(c);
					break;
				}
			}
		}, use_tls);

		host.onMessage = (client: hxbit.NetworkHost.NetworkClient, message: Dynamic) -> {
			if (on_message == null) return;
			if (client == null) on_message(null, message);

			var mp_client = get_multiplayer_client(client);
			if (mp_client == null) throw('Could not find client for message: $message');

			on_message(mp_client, message);
		}

		running = true;

		Sys.println('Listening on $bind_address:$bind_port');
	}

	function get_multiplayer_client(c: hxbit.NetworkHost.NetworkClient) {
		for (client in clients) if (client.client == c) return client;

		return null;
	}

	var elapsed = 0.0;
	var last_time = 0.0;

	public function update(dt: Float) {
		elapsed += dt;
		if (running && host != null && elapsed > 0.2) {
			elapsed = 0.0;
			host.flush();
		}
	}
}
