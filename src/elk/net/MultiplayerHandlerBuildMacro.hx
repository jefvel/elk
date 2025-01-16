package elk.net;

import haxe.macro.TypeTools;
import haxe.macro.Context;
import haxe.macro.Expr;

class MultiplayerHandlerBuildMacro {
	static public var T = macro : MultiplayerClient;

	public static function defineMultiplayerClient(typeName: String) {
		var t = Context.getType(typeName);
		var ClassType = TypeTools.toComplexType(t);

		T = ClassType;
		return null;
	}

	static public function build(): Array<Field> {
		var fields = Context.getBuildFields();

		fields = fields.concat((macro class {
			public var on_client_connected: $T -> Void = null;
			public var on_client_disconnected: $T -> Void = null;
		}).fields);

		var newField = {
			name: 'clients',
			doc: null,
			meta: [],
			access: [APublic],
			kind: FVar(macro : Array<$T>, macro []),
			pos: Context.currentPos()
		};
		fields.push(newField);

		var self = {
			name: 'self',
			doc: null,
			meta: [],
			access: [APublic],
			kind: FVar(T, macro null),
			pos: Context.currentPos()
		};
		fields.push(self);

		return fields;
	}
}
