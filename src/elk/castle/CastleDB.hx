package elk.castle;

using elk.extensions.ResTools;

private typedef Init = haxe.macro.MacroType<[cdb.Module.build("res/data.cdb")]>;

function init() {
	#if debug
	var txt = hxd.Res.data.entry.getText();
	CastleDB.load(txt, true);
	hxd.Res.data.watch(() -> {
		CastleDB.load(hxd.Res.data.entry.getText(), true);
	});
	#else
	var text = hxd.Res.data.entry.getJsonText();

	CastleDB.load(text);
	#end
}
