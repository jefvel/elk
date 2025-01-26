package elk.util;

import haxe.io.Float32Array;
import h3d.Vector4;

class BlendModes {
	static inline function blend_darken(a, b)
		return Math.min(a, b);

	static inline function blend_lighten(a, b)
		return Math.max(a, b);

	static inline function blend_burn(b, s) {
		if( b >= 1.0 ) return 1.0;
		b = (1 - b);
		if( b >= s ) return 0;
		else return 1 - b / s;
	}

	static inline function blend_divide(b, s) {
		if( b == 0.0 ) return 0.0;
		else if( b >= s ) return 1;
		else return b / s;
	}

	static inline function blend_multiply(b : Float, s : Float)
		return b * s;

	static inline function blend_screen(b : Float, s : Float)
		return b + s - b * s;

	public static inline function normal(src : Vector4, dst : Vector4, opacity : Float, ?res : Vector4) : Vector4 {
		if( res == null ) res = new Vector4();
		if( dst.a <= 0 ) {
			res.load(src);
			res.a *= opacity;
			return res;
		}

		res.load(dst);
		if( src.a <= 0 ) return res;

		var srcA = src.a * opacity;
		var resA = srcA + dst.a - (srcA * dst.a);

		res.load(dst);
		res.r += (src.r - dst.r) * srcA / resA;
		res.g += (src.g - dst.g) * srcA / resA;
		res.b += (src.b - dst.b) * srcA / resA;
		// res.scale3(1 - src.a);
		// res += src;

		res.a = resA;

		return res;
	}

	public static inline function addition(src : Vector4, dst : Vector4, opacity : Float, ?res : Vector4) : Vector4 {
		if( res == null ) res = new Vector4();
		var srcA = src.a * opacity;
		inline function blend(b : Float, s : Float)
			return Math.min(b + s, 1);

		src.r = blend(dst.r, src.r);
		src.g = blend(dst.g, src.g);
		src.b = blend(dst.b, src.b);

		return normal(src, dst, opacity, res);
	}

	public static inline function multiply(src : Vector4, dst : Vector4, opacity : Float, ?res : Vector4) : Vector4 {
		if( res == null ) res = new Vector4();

		src.r *= dst.r;
		src.g *= dst.g;
		src.b *= dst.b;

		return normal(src, dst, opacity, res);
	}

	public static inline function darken(src : Vector4, dst : Vector4, opacity : Float, ?res : Vector4) : Vector4 {
		if( res == null ) res = new Vector4();
		src.r = blend_darken(src.r, dst.r);
		src.g = blend_darken(src.g, dst.g);
		src.b = blend_darken(src.b, dst.b);

		return normal(src, dst, opacity, res);
	}

	public static inline function lighten(src : Vector4, dst : Vector4, opacity : Float, ?res : Vector4) : Vector4 {
		if( res == null ) res = new Vector4();
		src.r = blend_lighten(src.r, dst.r);
		src.g = blend_lighten(src.g, dst.g);
		src.b = blend_lighten(src.b, dst.b);

		return normal(src, dst, opacity, res);
	}

	public static inline function burn(src : Vector4, dst : Vector4, opacity : Float, ?res : Vector4) : Vector4 {
		if( res == null ) res = new Vector4();
		src.r = blend_burn(dst.r, src.r);
		src.g = blend_burn(dst.g, src.g);
		src.b = blend_burn(dst.b, src.b);

		return normal(src, dst, opacity, res);
	}

	public static inline function screen(src : Vector4, dst : Vector4, opacity : Float, ?res : Vector4) : Vector4 {
		if( res == null ) res = new Vector4();
		src.r = blend_screen(dst.r, src.r);
		src.g = blend_screen(dst.g, src.g);
		src.b = blend_screen(dst.b, src.b);

		return normal(src, dst, opacity, res);
	}

	public static inline function dodge(src : Vector4, dst : Vector4, opacity : Float, ?res : Vector4) : Vector4 {
		inline function blend_dodge(b : Float, s : Float) {
			if( b <= 0 ) return 0.0;
			s = 1.0 - s;
			if( b >= s ) return 1.0;
			else return b / s;
		}

		if( res == null ) res = new Vector4();
		src.r = blend_dodge(dst.r, src.r);
		src.g = blend_dodge(dst.g, src.g);
		src.b = blend_dodge(dst.b, src.b);

		return normal(src, dst, opacity, res);
	}

	public static inline function overlay(src : Vector4, dst : Vector4, opacity : Float, ?res : Vector4) : Vector4 {
		if( res == null ) res = new Vector4();
		src.r = blend_overlay(dst.r, src.r);
		src.g = blend_overlay(dst.g, src.g);
		src.b = blend_overlay(dst.b, src.b);
		return normal(src, dst, opacity, res);
	}

	public static inline function soft_light(src : Vector4, dst : Vector4, opacity : Float, ?res : Vector4) : Vector4 {
		if( res == null ) res = new Vector4();

		src.r = blend_soft_light(dst.r, src.r);
		src.g = blend_soft_light(dst.g, src.g);
		src.b = blend_soft_light(dst.b, src.b);

		return normal(src, dst, opacity, res);
	}

	public static inline function hard_light(src : Vector4, dst : Vector4, opacity : Float, ?res : Vector4) : Vector4 {
		if( res == null ) res = new Vector4();

		src.r = blend_hard_light(dst.r, src.r);
		src.g = blend_hard_light(dst.g, src.g);
		src.b = blend_hard_light(dst.b, src.b);

		return normal(src, dst, opacity, res);
	}

	public static inline function difference(src : Vector4, dst : Vector4, opacity : Float, ?res : Vector4) : Vector4 {
		if( res == null ) res = new Vector4();
		inline function blend_difference(a : Float, b : Float)
			return Math.abs(a - b);

		src.r = blend_difference(dst.r, src.r);
		src.g = blend_difference(dst.g, src.g);
		src.b = blend_difference(dst.b, src.b);

		return normal(src, dst, opacity, res);
	}

	public static inline function exclusion(src : Vector4, dst : Vector4, opacity : Float, ?res : Vector4) : Vector4 {
		if( res == null ) res = new Vector4();
		inline function blend(b : Float, s : Float) {
			var t = b * s;
			return b + s - 2 * t;
		}

		src.r = blend(dst.r, src.r);
		src.g = blend(dst.g, src.g);
		src.b = blend(dst.b, src.b);

		return normal(src, dst, opacity, res);
	}

	public static inline function subtract(src : Vector4, dst : Vector4, opacity : Float, ?res : Vector4) : Vector4 {
		if( res == null ) res = new Vector4();

		inline function blend(b : Float, s : Float)
			return Math.max(b - s, 0);

		src.r = blend(dst.r, src.r);
		src.g = blend(dst.g, src.g);
		src.b = blend(dst.b, src.b);

		return normal(src, dst, opacity, res);
	}

	public static inline function divide(src : Vector4, dst : Vector4, opacity : Float, ?res : Vector4) : Vector4 {
		if( res == null ) res = new Vector4();

		src.r = blend_divide(dst.r, src.r);
		src.g = blend_divide(dst.g, src.g);
		src.b = blend_divide(dst.b, src.b);

		return normal(src, dst, opacity, res);
	}

	static inline function blend_soft_light(b : Float, s : Float) {
		var d : Float = 0.0;
		var r : Float = 0.0;
		if( b <= 0.25 ) {
			d = ((16 * b - 12) * b + 4) * b;
		} else {
			d = Math.sqrt(b);
		}

		if( s <= 0.5 ) r = b - (1.0 - 2 * s) * b * (1.0 - b);
		else r = b + (2.0 * s - 1.0) * (d - b);

		return r + (1.0 / 255.0 * 0.5);
	}

	public static inline function hue(src : Vector4, dst : Vector4, opacity : Float, ?res : Vector4) : Vector4 {
		if( res == null ) res = new Vector4();

		var s = sat(dst.r, dst.g, dst.b);
		var l = lum(dst.r, dst.g, dst.b);

		set_sat(src, s);
		set_lum(src, l);

		return normal(src, dst, opacity, res);
	}

	public static inline function saturation(src : Vector4, dst : Vector4, opacity : Float, ?res : Vector4) : Vector4 {
		if( res == null ) res = new Vector4();

		var s = sat(src.r, src.g, src.b);
		var l = lum(dst.r, dst.g, dst.b);

		src.load(dst);
		set_sat(src, s);
		set_lum(src, l);

		return normal(src, dst, opacity, res);
	}

	public static inline function color(src : Vector4, dst : Vector4, opacity : Float, ?res : Vector4) : Vector4 {
		if( res == null ) res = new Vector4();

		var l = lum(dst.r, dst.g, dst.b);
		set_lum(src, l);

		return normal(src, dst, opacity, res);
	}

	public static inline function luminosity(src : Vector4, dst : Vector4, opacity : Float, ?res : Vector4) : Vector4 {
		if( res == null ) res = new Vector4();

		var l = lum(src.r, src.g, src.b);
		src.load(dst);
		set_lum(src, l);

		return normal(src, dst, opacity, res);
	}

	static var rgbArr = new Float32Array(3);

	static public inline function set_sat(c : Vector4, s : Float) {
		rgbArr[0] = c.r;
		rgbArr[1] = c.g;
		rgbArr[2] = c.b;

		var minI = c.r < c.g ? (c.r < c.b ? 0 : 2) : (c.g < c.b ? 1 : 2);
		var maxI = c.r > c.g ? (c.r > c.b ? 0 : 2) : (c.g > c.b ? 1 : 2);
		var midI = (c.r > c.g ? (c.g > c.b ? (1) : (c.r > c.b ? (2) : (0))) : (c.g > c.b ? (c.b > c.r ? (2) : (0)) : (1)));

		var max = rgbArr[maxI];
		var min = rgbArr[minI];
		var mid = rgbArr[midI];

		if( max > min ) {
			mid = ((mid - min) * s) / (max - min);
			max = s;
		} else {
			mid = max = 0;
		}

		min = 0.0;

		rgbArr[minI] = min;
		rgbArr[midI] = mid;
		rgbArr[maxI] = max;

		c.r = rgbArr[0];
		c.g = rgbArr[1];
		c.b = rgbArr[2];
	}

	static inline function clip_color(c : Vector4) {
		var l = lum(c.r, c.g, c.b);
		var n = Math.min(c.r, Math.min(c.g, c.b));
		var x = Math.max(c.r, Math.max(c.g, c.b));
		if( n < 0 ) {
			c.r = l + (((c.r - l) * l) / (l - n));
			c.g = l + (((c.g - l) * l) / (l - n));
			c.b = l + (((c.b - l) * l) / (l - n));
		}

		if( x > 1 ) {
			c.r = l + (((c.r - l) * (1 - l)) / (x - l));
			c.g = l + (((c.g - l) * (1 - l)) / (x - l));
			c.b = l + (((c.b - l) * (1 - l)) / (x - l));
		}
	}

	static inline function set_lum(c : Vector4, l : Float) {
		var d = l - lum(c.r, c.g, c.b);
		c.r += d;
		c.g += d;
		c.b += d;
		clip_color(c);
	}

	static inline function sat(r : Float, g : Float, b : Float)
		return Math.max(r, Math.max(g, b)) - Math.min(r, Math.min(g, b));

	static inline function lum(r : Float, g : Float, b : Float)
		return 0.3 * r + 0.59 * g + 0.11 * b;

	static inline function blend_overlay(b, s)
		return blend_hard_light(s, b);

	static inline function blend_hard_light(b : Float, s : Float)
		return s < 0.5 ? return blend_multiply(b, s * 2) : blend_screen(b, s * 2 - 1.0);
}
