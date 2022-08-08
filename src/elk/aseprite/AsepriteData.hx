package elk.aseprite;

enum AnimationDirection {
	Forward;
	Backward;
	PingPong;
}

@:structInit
class AseDataFrame {
	public var x:Int;
	public var y:Int;
	public var w:Int;
	public var h:Int;
	
	public var dx: Int;
	public var dy: Int;

	public var duration:Int;

	public var tile: h2d.Tile = null;
	public var slices: Map<String, AseDataSliceKey> = null;
}

@:structInit
class AseDataTag {
	public var name:String;
	public var duration:Int;
	public var constantSpeed:Bool;
	public var from: Int;
	public var to: Int;
	public var direction: AnimationDirection = Forward;
}

@:structInit
class AseDataSlice {
	public var name: String;
	public var keys: Array<AseDataSliceKey>;
}

@:structInit
class AseDataSliceKey {
	public var frame: Int;
	public var x: Int;
	public var y: Int;
	public var w: Int;
	public var h: Int;
}

@:structInit
class AsepriteData {
	public var width: Int = 0;
	public var height: Int = 0;

	public var frames: Array<AseDataFrame>;
	public var tags: Map<String, AseDataTag>;
	public var slices: Map<String, AseDataSlice>;
	
	public var totalDuration: Float = 0.;
	
	public var rootTile:h2d.Tile;

	public function new() {
	}
	
	public function copyFrom(data: AsepriteData) {
		width = data.width;
		height = data.height;
		
		totalDuration = data.totalDuration;
		rootTile = data.rootTile;

		for (i in 0...data.frames.length) {
			var oldFrame = frames[i];
			var newFrame = data.frames[i];
			if (oldFrame == null) {
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

		if (data.frames.length < frames.length) {
			frames.splice(data.frames.length, -1);
		}
		
		tags = data.tags;
		slices = data.slices;
		
	}
}