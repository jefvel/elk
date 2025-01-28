package elk.input;

import h2d.col.Point;

enum InputMethod {
	MouseAndKeyboard;
	Touch;
	Controller;
}

class InputHandler {
	public static inline function getAxis(negative_key : Int, positive_key : Int) {
		return (hxd.Key.isDown(positive_key) ? 1 : 0) - (hxd.Key.isDown(negative_key) ? 1 : 0);
	}

	public static function getVector(left_key : Int, right_key : Int, up_key : Int, down_key : Int, ?point : Point) {
		if( point == null ) point = new Point();
		point.x = getAxis(left_key, right_key);
		point.y = getAxis(up_key, down_key);
		point.normalize();
		return point;
	}
}
