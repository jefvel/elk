package elk.castle;

using elk.extensions.StringTools;

private typedef Init = haxe.macro.MacroType<[cdb.Module.build("res/data.cdb")]>;

function init() {
	#if debug
	CastleDB.load(hxd.Res.data.entry.getText(), true);
	hxd.Res.data.watch(() -> {
		CastleDB.load(hxd.Res.data.entry.getText(), true);
	});
	#else
	/*
		trace(haxe.macro.Compiler.getDefine('res_config'));
		var compressed = haxe.macro.Compiler.getDefine('res_config') == "web";
		var text:String = null;
		if (compressed) {
			var bytes = hxd.Res.data.entry.getBytes();
			var json = new hxd.fmt.hbson.Reader(bytes, true).read();
			text = haxe.Json.stringify(json);
		} else {
			text = hxd.Res.data.entry.getText();
			trace("no need");
		}
	 */

	var text = hxd.Res.data.entry.getJsonText();

	CastleDB.load(text);
	#end
}
