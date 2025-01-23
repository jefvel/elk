package elk.aseprite;

import hxd.fs.Convert.ConvertBinJSON;

enum AnimationDirection {
	Forward;
	Reverse;
	PingPong;
	PingPongReverse;
}

@:structInit
class AseDataFrame {
	public var x : Int;
	public var y : Int;
	public var w : Int;
	public var h : Int;

	public var dx : Int;
	public var dy : Int;

	public var duration : Int;

	public var tile : h2d.Tile = null;
	public var slices : Map<String, AseDataSliceKey> = null;
}

@:structInit
class AseDataTag {
	public var name : String;
	public var duration : Int;
	public var constantSpeed : Bool;
	public var from : Int;
	public var to : Int;
	public var direction : AnimationDirection = Forward;
	public var repeat : Bool;

	public function toString() {
		return '$name [$from - $to], duration: $duration, constant: $constantSpeed, direction: $direction, repeat: $repeat';
	}
}

@:structInit
class AseDataSlice {
	public var name : String;
	public var keys : Array<AseDataSliceKey>;

	public function toString() {
		return '$name: [\n${keys.map(k -> '  frame: ${k.frame}, x:${k.x}, y: ${k.y} (${k.w}x${k.h})').join('\n')}\n]';
	}
}

@:structInit
class AseDataSliceKey {
	public var frame : Int;
	public var x : Int;
	public var y : Int;
	public var w : Int;
	public var h : Int;
}

@:structInit
class AsepriteData {
	public var width : Int = 0;
	public var height : Int = 0;

	public var frames : Array<AseDataFrame> = [];
	public var tags : Map<String, AseDataTag> = new Map();
	public var slices : Map<String, AseDataSlice> = new Map();

	public var totalDuration : Float = 0.;

	public var rootTile : h2d.Tile;

	public function new() {}

	public function copyFrom(data : AsepriteData) {
		width = data.width;
		height = data.height;

		totalDuration = data.totalDuration;
		rootTile = data.rootTile;

		for (i in 0...data.frames.length) {
			var oldFrame = frames[i];
			var newFrame = data.frames[i];
			if( oldFrame == null ) {
				frames.push(newFrame);
			} else {
				oldFrame.x = newFrame.x;
				oldFrame.y = newFrame.y;
				oldFrame.duration = newFrame.duration;
				oldFrame.dx = newFrame.dx;
				oldFrame.dy = newFrame.dy;
				oldFrame.slices = newFrame.slices;
				oldFrame.tile = newFrame.tile;
				oldFrame.w = newFrame.w;
				oldFrame.h = newFrame.h;
			}
		}

		if( data.frames.length < frames.length ) {
			frames.splice(data.frames.length, -1);
		}

		tags = data.tags;
		slices = data.slices;
	}

	private static inline function dynToMap(objo) : Map<String, Dynamic> {
		var res = new Map();
		var obj : haxe.DynamicAccess<Dynamic> = objo;
		for (key in obj.keys()) {
			res.set(key, obj.get(key).value);
		}
		return res;
	}

	public static function load(entry : hxd.fs.FileEntry) : AsepriteData {
		return haxe.Unserializer.run(entry.getText());

		/*
			var bytes = entry.getBytes();
			var reader = new hxd.fmt.hbson.Reader(bytes, true);
			var data = haxe.Json.parse(reader.read());
			var res = new AsepriteData();
			res.frames = data.frames;
			res.width = data.width;
			res.height = data.height;
			res.slices = cast dynToMap(data.slices);
			res.tags = cast dynToMap(data.tags);
			res.totalDuration = data.totalDuration;
			return res;
		 */
	}

	public function writeToFile(destPath : String) {
		/*
			var json = haxe.Json.stringify(this);
			var out = new haxe.io.BytesOutput();
			new hxd.fmt.hbson.Writer(out).write(json);
			hxd.File.saveBytes(destPath, out.getBytes());
		 */
		var bytes = haxe.io.Bytes.ofString(haxe.Serializer.run(this));
		hxd.File.saveBytes(destPath, bytes);
	}
}
