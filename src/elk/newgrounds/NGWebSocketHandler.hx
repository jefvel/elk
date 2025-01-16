package elk.newgrounds;

import elk.newgrounds.ValidateNGSession;

#if sys
class NGWebSocketHandler extends hx.ws.WebSocketHandler {
	public var username(default, null): String = null;
	public var session(default, null): String = null;

	public function new(s: hx.ws.SocketImpl) {
		super(s);

		validateHandshake = (req, resp, cb) -> {
			function unauthorized() {
				resp.code = 403;
				resp.text = "Unauthorized";
				resp.headers.set(hx.ws.HttpHeader.CONNECTION, "close");
				resp.headers.set(hx.ws.HttpHeader.X_WEBSOCKET_REJECT_REASON, 'Unauthorized');
				cb(resp);
			}

			resp.headers.set(hx.ws.HttpHeader.SEC_WEBSOCKET_PROTOCOL, 'auth_token');
			return cb(resp);

			try {
				var protocols = req.headers.get(hx.ws.HttpHeader.SEC_WEBSOCKET_PROTOCOL);
				if (protocols == null) return unauthorized();

				var split = protocols.split(',').map(s -> StringTools.trim(s));
				var type = split[0];
				if (type != 'auth_token') {
					return unauthorized();
				}

				var hashed = split[1];
				var split = haxe.crypto.Base64.urlDecode(hashed).toString().split(':');
				var username = split[0];
				var session = split[1];

				ValidateNGSession(username, session, function(valid) {
					if (!valid) {
						return unauthorized();
					}

					this.username = username;
					this.session = session;

					resp.headers.set(hx.ws.HttpHeader.SEC_WEBSOCKET_PROTOCOL, type);

					cb(resp);
				});
			}
			catch (err) {
				trace('handshake check error.');
				unauthorized();
			}
		};
	}
}
#end
