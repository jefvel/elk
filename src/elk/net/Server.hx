package elk.net;

import net.RootObject;
import elk.newgrounds.NGWebSocketHandler;
import elk.net.MultiplayerClient;

@:generic
class Server<T : haxe.Constraints.Constructible<(hxbit.NetworkHost.NetworkClient, hxbit.NetworkHost) -> Void> & MultiplayerClient> {
	var running = false;

	public var on_message : (T, Dynamic) -> Void;
	public var on_player_connected : (T) -> Void;
	public var on_player_disconnected : (T) -> Void;

	var max_users = 100;
	var bind_address = '0.0.0.0';
	var bind_port = 9999;

	var rootObject : RootObject;

	public var handler : MultiplayerHandler;

	#if !use_sockets
	public var host : elk.net.WebSocketHost = null;
	#else
	public var host : hxd.net.SocketHost = null;
	#end
	public var players : Array<T> = [];

	public function new(address = '0.0.0.0', port = 9999, max_users = 100, handler : MultiplayerHandler) {
		this.bind_address = address;
		this.bind_port = port;
		this.max_users = max_users;
		this.handler = handler;
		start();
	}

	public function stop() {
		if( !running ) return;
		running = false;
		host.dispose();
		host = null;
	}

	public function start(offline_server = false) {
		stop();

		#if !use_sockets
		host = new elk.net.WebSocketHost();
		#else
		host = new hxd.net.SocketHost();
		#end

		#if true
		host.setLogger((t) -> trace(t));
		#end

		if( offline_server ) {
			host.offlineServer();
		} else {
			host.wait(bind_address, bind_port, (client) -> {
				var user = new T(client, host);
				client.sendMessage('uid:${user.uid}');
				players.push(user);
				#if hxbit_visibility
				rootObject.players.push(cast user);
				#end
				client.sync();
				/*
					if( on_player_connected != null ) on_player_connected(user);
				 */
			}, (client) -> {
				var player = get_player(client);
				if( player == null ) return;

				players.remove(player);
				player.enableReplication = false;

				handler.on_unregister(player);

				#if hxbit_visibility
				rootObject.players.remove(cast player);
				#end

				// if( on_player_disconnected != null ) on_player_disconnected(player);
			});
		}

		#if hxbit_visibility
		host.lateRegistration = true;
		rootObject = new RootObject(host.self);
		host.rootObject = rootObject;
		#end

		host.onMessage = (client : hxbit.NetworkHost.NetworkClient, message : Dynamic) -> {
			if( on_message == null ) return;

			if( client == null ) on_message(null, message);

			var player = get_player(client);
			if( player == null ) throw('Could not find player for message: $message');

			on_message(player, message);
		}

		running = true;

		Sys.println('Listening on $bind_address:$bind_port');
	}

	function get_player(c : hxbit.NetworkHost.NetworkClient) {
		for (client in players) if( client.client == c ) return client;

		return null;
	}

	var elapsed = 0.0;
	var last_time = 0.0;

	public function update(dt : Float) {
		elapsed += dt;
		// host.checkReferences();
		if( running && host != null && elapsed > 0.2 ) {
			elapsed = 0.0;
			host.flush();
		}
	}
}
