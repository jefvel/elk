package elk.newgrounds;

import haxe.Http;
import haxe.http.HttpBase;

function GenerateConnectionHash(username : String, password : String) {
	return haxe.crypto.Base64.urlEncode(haxe.io.Bytes.ofString('$username:$password'));
}

function DecodeConnectionHash(hashed : String) {
	var split = haxe.crypto.Base64.decode(hashed).toString().split(':');
	return {
		username : split[0],
		password : split[1],
	}
}

function ValidateNGSession(username : String, session_id : String, callback : (session_valid : Bool) -> Void) {
	var req = new Http('https://www.newgrounds.io/gateway_v3.php');
	var data = {
		app_id : haxe.macro.Compiler.getDefine('newgroundsAppId'),
		session_id : session_id,
		execute : {
			component : 'App.checkSession'
		}
	}
	var json = haxe.Json.stringify(data);
	req.setParameter('input', json);
	req.onData = (response) -> {
		try {
			var data = haxe.Json.parse(response);
			if( !data.success ) {
				callback(false);
				return;
			}
			var result_data = data?.result?.data;
			if( !result_data?.success ) {
				callback(false);
				return;
			}
			var session = result_data.session;
			var valid = session?.user?.name == username && !session.expired;
			callback(valid);
		} catch (_) {
			callback(false);
		}
	}
	req.request(true);
}
