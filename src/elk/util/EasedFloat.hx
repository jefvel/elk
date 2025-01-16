package elk.util;

class EasedFloat {
	public var value(get, set): Float;

	public var easeTime = 0.3;
	public var easeFunction: (Float) -> Float = M.expoOut;

	public var timeScale = 1.0;

	public var targetValue = 0.;

	var from = 0.;

	var changeTime = 0.;

	var internalValue = 0.;

	public function new(initial: Float = 0., easeTime = 0.3) {
		this.easeTime = easeTime;
		setImmediate(initial);
	}

	public function setImmediate(value: Float) {
		targetValue = from = value;
		changeTime = easeTime;
	}

	function set_value(v) {
		if (v == targetValue) {
			return v;
		}

		from = targetValue;
		targetValue = v;

		changeTime = hxd.Timer.lastTimeStamp;

		return v;
	}

	function get_value() {
		var t = hxd.Timer.lastTimeStamp - changeTime;
		t *= timeScale;

		if (t > easeTime) {
			return targetValue;
		}

		var r = Math.min(1, t / easeTime);
		var p = easeFunction != null ? easeFunction(r) : r;
		return from + p * (targetValue - from);
	}

	public static inline function elastic(initial, easeTime) {
		var f = new EasedFloat(initial, easeTime);
		f.easeFunction = elk.M.elasticOut;
		return f;
	}

	public static inline function bounce(initial, easeTime) {
		var f = new EasedFloat(initial, easeTime);
		f.easeFunction = elk.M.bounceOut;
		return f;
	}

	public static inline function smootherstep_in_out(initial, easeTime) {
		var f = new EasedFloat(initial, easeTime);
		f.easeFunction = elk.M.smootherStepInOut;
		return f;
	}
}
