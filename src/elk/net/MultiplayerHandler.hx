package elk.net;

/**
 * Keeps track of connected players, both on client side and server
 */
@:build(elk.net.MultiplayerHandlerBuildMacro.build())
class MultiplayerHandler {
	public static var instance(get, null): MultiplayerHandler;
	static var _instance: MultiplayerHandler = null;

	public var host(default, set): hxbit.NetworkHost = null;

	private var own_uid: String = null;

	public function new() {}

	public function set_own_uid(uid: String, client: hxbit.NetworkHost.NetworkClient) {
		own_uid = uid;
	}

	public function get_own_uid() {
		return own_uid;
	}

	public function reset() {
		for (c in clients) remove_client(c);
		self = null;
		own_uid = null;
	}

	public function add_client(c) {
		if (!clients.contains(c)) clients.push(c);

		if (c.uid == own_uid) {
			c.client = host.self;
			c.client.ownerObject = c;
			self = c;
		}

		if (on_client_connected != null) {
			on_client_connected(c);
		}
		trace('client added.');
	}

	public function remove_client(c) {
		clients.remove(c);
		c.on_disconnect();
		if (on_client_disconnected != null) on_client_disconnected(c);
		trace('removing client');
	}

	static function get_instance() {
		if (_instance == null) _instance = new MultiplayerHandler();
		return _instance;
	}

	public function on_unregister(c: hxbit.NetworkSerializable) {
		for (client in clients) {
			if (client.client.ownerObject == c) {
				remove_client(client);
				break;
			}
		}
	}

	function set_host(h: hxbit.NetworkHost) {
		h.onUnregister = on_unregister;
		return this.host = h;
	}
}
