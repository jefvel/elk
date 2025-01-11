package elk.net;

/**
 * Keeps track of connected players, both on client side and server
 */
class MultiplayerHandler<T:MultiplayerClient = MultiplayerClient> {
	public static var instance(get, null):MultiplayerHandler;

	static var _instance:MultiplayerHandler = null;

	public var host:hxbit.NetworkHost = null;

	public var clients(default, null):Array<T> = [];

	private var own_uid:String = null;

	public var self:T = null;

	public function new() {}

	public function reset() {
		for (c in clients)
			remove_client(c);
		self = null;
		own_uid = null;
		host = null;
	}

	public function add_client(c:T) {
		if (!clients.contains(c))
			clients.push(c);

		if (c.uid == own_uid) {
			c.client = host.self;
			c.client.ownerObject = c;
			self = c;
		}
	}

	public function remove_client(c:T) {
		clients.remove(c);
	}

	public function set_own_uid(uid:String, client:hxbit.NetworkHost.NetworkClient) {
		own_uid = uid;
		/*
			for (c in clients) {
				if (c.uid == uid) {
					client.ownerObject = c;
					c.client = client;
					self = c;
				}
			}
		 */
	}

	public function get_own_uid() {
		return own_uid;
	}

	static function get_instance() {
		if (_instance == null)
			_instance = new MultiplayerHandler();
		return _instance;
	}
}
