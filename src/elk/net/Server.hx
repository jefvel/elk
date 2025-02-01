package elk.net;

import hxbit.NetworkHost.NetworkClient;
import elk.newgrounds.NGWebSocketHandler;
import elk.net.MultiplayerClient;

class Server {
	var running = false;

	public var on_message : (NetworkClient, Dynamic) -> Void;
	public var on_client_connected : (NetworkClient) -> Void;
	public var on_client_disconnected : (NetworkClient) -> Void;

	var max_users = 100;
	var bind_address = '0.0.0.0';
	var bind_port = 9999;

	#if use_websockets
	public var host : elk.net.WebSocketHost = null;
	#else
	public var host : elk.net.SocketHost = null;
	#end

	public function new(address = '0.0.0.0', port = 9999, max_users = 100, auto_start = false) {
		this.bind_address = address;
		this.bind_port = port;
		this.max_users = max_users;
		if( auto_start ) start();
	}

	public function stop() {
		if( !running ) return;
		running = false;
		if( host == null ) return;
		host.dispose();
		host = null;
	}

	public function start(offline_server = false) {
		stop();

		#if use_websockets
		host = new elk.net.WebSocketHost();
		#else
		host = new elk.net.SocketHost();
		#end

		#if true
		host.setLogger((t) -> {
			// trace(t);
		});
		#end

		if( offline_server ) {
			host.offlineServer();
		} else {
			host.wait(bind_address, bind_port, (client) -> {
				// var user = new T(client, host);
				// client.sendMessage('uid:${user.uid}');
				// players.push(user);
				#if hxbit_visibility
				#end
				// client.sync();
				if( on_client_connected != null ) on_client_connected(client);
			}, (client) -> {
				/*
					var player = get_player(client);
					if( player == null ) return;

					players.remove(player);
					player.enableReplication = false;

					handler.on_unregister(player);

					#if hxbit_visibility
					#end
				 */
				trace('client disocnnnected');

				if( on_client_disconnected != null ) on_client_disconnected(client);
			});
		}

		#if hxbit_visibility
		host.lateRegistration = true;
		#end

		host.onMessage = (client : hxbit.NetworkHost.NetworkClient, message : Dynamic) -> {
			if( on_message == null ) return;

			on_message(client, message);
			/*
				if( client == null ) on_message(null, message);

				var player = get_player(client);
				if( player == null ) throw('Could not find player for message: $message');

				on_message(player, message);
			 */
		}

		running = true;
	}

	var elapsed = 0.0;
	var last_time = 0.0;

	public function update(dt : Float) {
		elapsed += dt;
		if( running && host != null && elapsed > 0.2 ) {
			elapsed = 0.0;
			host.flush();
		}
	}
}
