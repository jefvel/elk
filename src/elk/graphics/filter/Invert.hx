package elk.graphics.filter;

import h2d.filter.Filter;

/**
	Inverts the color
	@see `Ambient`
**/
class Invert extends Filter {

	/**
		The amount to invert, (1 = full invert, 0 = original image)
	**/
	public var invertPower(get, set) : Float;

	var pass : elk.graphics.pass.Invert;

	public function new( invertPower = 1.0 ) {
		super();
		pass = new elk.graphics.pass.Invert(invertPower);
		pass.shader.useAlpha = true;
	}

	inline function get_invertPower() return pass.invertPower;
	inline function set_invertPower(p) return pass.invertPower = p;

	override function draw( ctx : h2d.RenderContext, t : h2d.Tile ) {
		var tout = ctx.textures.allocTileTarget("invertOut", t);
		pass.apply(t.getTexture(), tout);
		return h2d.Tile.fromTexture(tout);
	}
}
