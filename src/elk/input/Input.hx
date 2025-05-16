package elk.input;

import h2d.col.Point;

enum InputMethod {
	MouseAndKeyboard;
	Touch;
	Controller;
}

class Input {
	public static var instance(get, null) : Input;

	public static var disableInput = false;

	#if js
	public var touchId = null;
	#else
	public var touchId = 0;
	#end

	#if !disableGamepads
	public var gamepads : GamepadHandler;
	#end

	static function get_instance() {
		return instance;
	}

	var elk : Elk = null;

	function new(elk : Elk) {
		#if !disableGamepads
		gamepads = new GamepadHandler();
		#end
		this.elk = elk;

		hxd.Window.getInstance().addEventTarget(handleEvent);
	}

	public static function init(elk : Elk) {
		if( instance == null ) instance = new Input(elk);
		return instance;
	}

	public static inline function isKeyDown(key : Int) {
		return !disableInput && hxd.Key.isDown(key);
	}

	public static inline function isKeyPressed(key : Int) {
		return !disableInput && hxd.Key.isPressed(key);
	}

	public static inline function isKeyReleased(key : Int) {
		return !disableInput && hxd.Key.isReleased(key);
	}

	public static inline function getAxis(negative_key : Int, positive_key : Int) {
		return (hxd.Key.isDown(positive_key) ? 1 : 0) - (hxd.Key.isDown(negative_key) ? 1 : 0);
	}

	public static function getVector(left_key : Int, right_key : Int, up_key : Int, down_key : Int, ?point : Point) {
		if( point == null ) point = new Point();
		if( disableInput ) {
			point.set();
			return point;
		}
		point.x = getAxis(left_key, right_key);
		point.y = getAxis(up_key, down_key);
		point.normalize();
		return point;
	}

	public var mouseX : Float = 0.0;
	public var mouseY : Float = 0.0;

	function handleEvent(e : hxd.Event) {
		if( e.kind == EMove ) {
			#if js
			if( e.touchId == null || e.touchId == touchId ) {
			#end
				var win = hxd.Window.getInstance();
				var ratio = elk.s2d.width / win.width;
				mouseX = e.relX * ratio;
				mouseY = e.relY * ratio;
				return true;
			#if js
			}
			#end
		}
		#if js
		if( e.kind == EPush ) {
			if( e.touchId != null && touchId == null ) {
				touchId = e.touchId;
				return true;
			}
		}
		if( e.kind == ERelease || e.kind == EReleaseOutside ) {
			if( e.touchId == touchId ) {
				touchId = null;
				return true;
			}
		}
		#end
		return false;
	}
}
