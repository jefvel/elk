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

	#if !disableGamepads
	public var gamepads : GamepadHandler;
	#end

	static function get_instance() {
		if( instance == null ) instance = new Input();
		return instance;
	}

	function new() {
		#if !disableGamepads
		gamepads = new GamepadHandler();
		#end
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
}
