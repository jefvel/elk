package elk.res;

class ConvertBinJSON extends hxd.fs.Convert {
	override function convert() {
		var json = haxe.Json.parse(srcBytes.toString());
		var out = new haxe.io.BytesOutput();
		new hxd.fmt.hbson.Writer(out).write(json);
		save(out.getBytes());
	}

	static var _ = [hxd.fs.Convert.register(new ConvertBinJSON("cdb,json,ldtk", "hbson"))];
}
