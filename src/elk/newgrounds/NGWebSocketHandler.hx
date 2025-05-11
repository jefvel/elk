package elk.newgrounds;

#if sys
import hx.ws.HttpResponse;
import hx.ws.HttpRequest;
import elk.newgrounds.ValidateNGSession;

class NGWebSocketHandler {
	public static function validateHandshake(client : hx.ws.Handler, req : HttpRequest, resp : HttpResponse, cb : (HttpResponse) -> Void) {
		function unauthorized() {
			resp.code = 403;
			resp.text = "Unauthorized";
			resp.headers.set(hx.ws.HttpHeader.CONNECTION, "close");
			resp.headers.set(hx.ws.HttpHeader.X_WEBSOCKET_REJECT_REASON, 'Unauthorized');
			cb(resp);
		}

		resp.headers.set(hx.ws.HttpHeader.SEC_WEBSOCKET_PROTOCOL, 'auth_token');

		try {
			var protocols = req.headers.get(hx.ws.HttpHeader.SEC_WEBSOCKET_PROTOCOL);
			if( protocols == null ) return unauthorized();

			var split = protocols.split(',').map(s -> StringTools.trim(s));
			var type = split[0];
			if( type != 'auth_token' ) {
				return unauthorized();
			}

			var hashed = split[1];

			var split = DecodeConnectionHash(hashed);

			var username = split.username;
			var session = split.password;
			if( username == null || username.length == 0 ) {
				return unauthorized();
			}

			if( StringTools.endsWith(req.uri, 'healthz') || StringTools.endsWith(req.uri, 'livez') ) {
				resp.code = 200;
			}

			resp.headers.set(hx.ws.HttpHeader.SEC_WEBSOCKET_PROTOCOL, 'auth_token');

			if( session == null || session.length == 0 ) {
				return unauthorized();
			}

			ValidateNGSession(username, session, function(valid) {
				if( !valid ) {
					return unauthorized();
				}

				client.metadata.set('username', username);
				client.metadata.set('session', session);

				resp.headers.set(hx.ws.HttpHeader.SEC_WEBSOCKET_PROTOCOL, type);

				cb(resp);
			});
		} catch (err) {
			trace('handshake check error.');
			unauthorized();
		}
	}

	/**
	 * fetches the newgrounds username + session from a connected client. If it's not
	 * a newgrounds connection, it will return null.
	 * @param client 
	 */
	public static function get_session_info(client : hxbit.NetworkHost.NetworkClient) {
		if( client is elk.net.WebSocketHost.WebSocketHandlerClient ) {
			var cl = cast(client, elk.net.WebSocketHost.WebSocketHandlerClient);
			var metadata = cl.socket.metadata;
			if( metadata.exists('session_id') && metadata.exists('username') ) {
				return {
					username : metadata.get('username'),
					session_id : metadata.get('session_id'),
				}
			}
		}

		return null;
	}
}
#end
