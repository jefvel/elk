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
	public var duration:Int;
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

	public function new() {
		
	}
}