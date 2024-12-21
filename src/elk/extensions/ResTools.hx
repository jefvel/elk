package elk.extensions;

class ResTools {
	static inline function isBinJson(bytes:haxe.io.Bytes) {
		return bytes.getString(0, 5) == 'HBSON';
	}

	static inline function convertBinJson(bytes:haxe.io.Bytes) {
		var reader = new hxd.fmt.hbson.Reader(bytes, true);
		return reader.read();
	}

	static public function getJsonText(entry:hxd.fs.FileEntry):String {
		var bytes = entry.getBytes();
		if (!isBinJson(bytes))
			return entry.getText();

		return haxe.Json.stringify(convertBinJson(bytes));
	}

	static public function getJson(entry:hxd.fs.FileEntry):Dynamic {
		var bytes = entry.getBytes();
		if (isBinJson(bytes)) {
			return convertBinJson(bytes);
		}

		return haxe.Json.parse(entry.getText());
	}
}
