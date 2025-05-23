package elk;

typedef RGB = {
	var r : Float;
	var g : Float;
	var b : Float;
}

/**
 * Easing functions
 */
class M {
	static final PI2 : Float = Math.PI / 2;

	static final EL : Float = 2 * Math.PI / .45;
	static final B1 : Float = 1 / 2.75;
	static final B2 : Float = 2 / 2.75;
	static final B3 : Float = 1.5 / 2.75;
	static final B4 : Float = 2.5 / 2.75;
	static final B5 : Float = 2.25 / 2.75;
	static final B6 : Float = 2.625 / 2.75;
	static final ELASTIC_AMPLITUDE : Float = 1;
	static final ELASTIC_PERIOD : Float = 0.4;

	public static inline function sign(i : Float) {
		if( i < 0 ) return -1;
		return 1;
	}

	public static inline function toRGB(int : Int) : RGB {
		return {
			r : ((int >> 16) & 255) / 255,
			g : ((int >> 8) & 255) / 255,
			b : (int & 255) / 255,
		}
	}

	public static inline function smoothstep(from : Float, to : Float, x : Float) {
		x = clamp((x - from) / (to - from), 0., 1.);
		return x * x * (3. - 2. * x);
	}

	public static inline function linear(from : Float, to : Float, x : Float) : Float {
		var start = (x - from);
		var d = to - from;
		return clamp(start / d, 0, 1);
	}

	public static inline function mix(a : Float, b : Float, x : Float) {
		var p = clamp(x);
		return a * (1 - p) + b * p;
	}

	public static inline function smootherstep(from : Float, to : Float, x : Float) {
		x = clamp((x - from) / (to - from), 0., 1.);
		return x * x * x * (x * (x * 6. - 15.) + 10.);
	}

	public static inline function tickLerp(from : Float, to : Float, sharpness = 0.3, scale = 1.0) {
		var d = to - from;
		var s = sharpness;
		if( scale != 1.0 ) s = 1.0 - Math.pow(1.0 - sharpness, scale);

		return from + d * s;
	}

	public static inline function lerpDt(from : Float, to : Float, dt : Float, halfTime : Float) {
		var dd = (-dt / halfTime);
		return to + (from - to) * Math.exp(dd);
	}

	public static inline function clamp(x : Float, lower = 0., upper = 1.) {
		if( x < lower ) return lower;
		if( x > upper ) return upper;
		return x;
	}

	public static inline function quintIn(t : Float) : Float {
		return t * t * t * t * t;
	}

	public static inline function sineIn(t : Float) : Float {
		return -Math.cos(PI2 * t) + 1;
	}

	public static inline function expoIn(t : Float) : Float {
		return Math.pow(2, 10 * (t - 1));
	}

	public static inline function expoOut(t : Float) : Float {
		return -Math.pow(2, -10 * t) + 1;
	}

	public static inline function quintOut(t : Float) : Float {
		return (t = t - 1) * t * t * t * t + 1;
	}

	public static inline function smootherStepInOut(t : Float) : Float {
		return t * t * t * (t * (t * 6 - 15) + 10);
	}

	public static function bounceIn(t : Float) : Float {
		t = 1 - t;
		if( t < B1 ) return 1 - 7.5625 * t * t;
		if( t < B2 ) return 1 - (7.5625 * (t - B3) * (t - B3) + .75);
		if( t < B4 ) return 1 - (7.5625 * (t - B5) * (t - B5) + .9375);
		return 1 - (7.5625 * (t - B6) * (t - B6) + .984375);
	}

	public static function bounceOut(t : Float) : Float {
		if( t < B1 ) return 7.5625 * t * t;
		if( t < B2 ) return 7.5625 * (t - B3) * (t - B3) + .75;
		if( t < B4 ) return 7.5625 * (t - B5) * (t - B5) + .9375;
		return 7.5625 * (t - B6) * (t - B6) + .984375;
	}

	public static inline function elasticIn(t : Float) : Float {
		return -(ELASTIC_AMPLITUDE * Math.pow(2,
			10 * (t -= 1)) * Math.sin((t - (ELASTIC_PERIOD / (2 * Math.PI) * Math.asin(1 / ELASTIC_AMPLITUDE))) * (2 * Math.PI) / ELASTIC_PERIOD));
	}

	public static inline function elasticOut(t : Float) : Float {
		return (ELASTIC_AMPLITUDE * Math.pow(2,
			-10 * t) * Math.sin((t - (ELASTIC_PERIOD / (2 * Math.PI) * Math.asin(1 / ELASTIC_AMPLITUDE))) * (2 * Math.PI) / ELASTIC_PERIOD)
			+ 1);
	}

	public static inline function timestamp() {
		return #if sys Sys.time() #elseif js js.lib.Date.now() * 0.001 #else haxe.Date.now().getTime() #end;
	}
}
