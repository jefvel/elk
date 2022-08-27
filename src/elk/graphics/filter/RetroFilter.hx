package elk.graphics.filter;

import elk.graphics.pass.RetroPass;
import h2d.Object;
import h2d.RenderContext;
import h2d.filter.Filter;

/**
	Utilizes the `h3d.pass.Blur` render pass to perform a blurring operation on the filtered object.
**/
class RetroFilter extends Filter {

	/**
		@see `h3d.pass.Blur.radius`
	**/
	public var radius(get, set) : Float;

	/**
		@see `h3d.pass.Blur.linear`
	**/
	public var linear(get, set) : Float;

	/**
		@see `h3d.pass.Blur.gain`
	**/
	public var gain(get, set) : Float;

	/**
		@see `h3d.pass.Blur.quality`
	**/
	public var quality(get, set) : Float;
	
	public var waviness(get, set): Float;
	public var sharpness(get, set): Float;
	public var noise(get, set): Float;

	var pass : RetroPass;

	/**
		Create a new Blur filter.
		@param radius The blur distance in pixels.
		@param gain The color gain when blurring.
		@param quality The sample count on each pixel as a tradeoff of speed/quality.
		@param linear Linear blur power. Set to 0 for gaussian blur.
	**/
	public function new( radius = 1., sharpness = 0.1, noise = 0.5, gain = 1., quality = 1., linear = 0.) {
		super();
		smooth = true;
		pass = new RetroPass(radius, gain, linear, quality);
		useScreenResolution = true;
		pass.noise = noise;
		pass.radius = radius;
		pass.linear = linear;
		pass.sharpness = sharpness;
	}

	inline function get_quality() return pass.quality;
	inline function set_quality(v) return pass.quality = v;
	inline function get_radius() return pass.radius;
	inline function set_radius(v) return pass.radius = v;
	inline function get_gain() return pass.gain;
	inline function set_gain(v) return pass.gain = v;
	inline function get_linear() return pass.linear;
	inline function set_linear(v) return pass.linear = v;
	inline function get_waviness() return pass.waviness;
	inline function set_waviness(v) return pass.waviness = v;

	inline function get_sharpness() return pass.sharpness;
	inline function set_sharpness(v) return pass.sharpness = v;

	inline function get_noise() return pass.noise;
	inline function set_noise(v) return pass.noise = v;

	override function sync( ctx : RenderContext, s : Object ) {
		boundsExtend = radius * 2;
	}

	override function draw( ctx : RenderContext, t : h2d.Tile ) {
		var out = t.getTexture();
		var old = out.filter;
		out.filter = Linear;
		pass.apply(ctx, out);
		out.filter = old;
		return t;
	}
}
