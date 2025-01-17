package elk.net;

import hxbit.NetworkHost.NetworkClient;

@:keepSub
class MultiplayerClient implements hxbit.NetworkSerializable {
	@:s @:notMutable public var uid: String;

	public var connected(default, null) = false;
	public var client: NetworkClient = null;

	public var is_self(default, null): Bool = false;

	var host: hxbit.NetworkHost;

	public function new(client: NetworkClient, host: hxbit.NetworkHost) {
		uid = elk.util.Uuid.v4();

		this.host = host;
		this.client = client;

		client.ownerObject = this;
		this.enableReplication = true;
		#if hxbit_visibility
		// this.setVisibilityDirty(hxbit.VisibilityGroup.Test);
		#end

		_init();
	}

	public function evalVisibility(group: hxbit.VisibilityGroup, from: hxbit.NetworkSerializable): Bool {
		trace('eval visibility MultiplayerClient');
		return true;
	}

	public function networkAllow(op: hxbit.NetworkSerializable.Operation, propId: Int, client: hxbit.NetworkSerializable): Bool {
		var allow = client == this;
		return allow;
	}

	public function on_disconnect() {
		connected = false;
	}

	public function on_connect() {}

	function _init() {
		connected = true;
		this.is_self = MultiplayerHandler.instance.get_own_uid() == uid;
		MultiplayerHandler.instance.add_client(cast this);
	}

	public function alive() {
		_init();
		on_connect();
		trace('new client: $uid, self: $is_self');
	}
}
