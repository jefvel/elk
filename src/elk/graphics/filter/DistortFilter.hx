package elk.graphics.filter;

import h2d.filter.Filter;
import elk.graphics.shader.DistortShader;
import h3d.shader.ScreenShader;
import h3d.shader.NoiseLib;
import h3d.Vector;
import h3d.mat.Texture;
import h2d.RenderContext;
import h2d.filter.AbstractMask;

class DistortFilter extends Filter {
	var pass : h3d.pass.ScreenFx<DistortShader>;

	public var offset(get, set) : Vector;

	var bayer : Texture;

	public function new() {
		super();
		new ScreenShader();
		new NoiseLib();
		pass = new h3d.pass.ScreenFx(new DistortShader());
		bayer = hxd.Res.img.bayer8.toTexture();
		bayer.filter = Nearest;
		bayer.wrap = Repeat;
	}

	function get_offset()
		return pass.shader.offset;

	function set_offset(v)
		return pass.shader.offset = v;

	override function draw(ctx : RenderContext, t : h2d.Tile) {
		var game = elk.Elk.instance;
		pass.shader.screenSize.set(game.s2d.width, game.s2d.height);

		var out = ctx.textures.allocTileTarget("distortTmp", t);
		ctx.engine.pushTarget(out);
		pass.shader.texture = t.getTexture();
		pass.render();
		ctx.engine.popTarget();
		return h2d.Tile.fromTexture(out);
	}
}
