package elk.graphics.pass;

private class CompositeShader extends h3d.shader.ScreenShader {
	static var SRC = {
		@param var texture : Sampler2D;
		@param var composite : Sampler2D;

		function fragment() {
			pixelColor = texture.get(calculatedUV);
			var outval = composite.get(calculatedUV).rgba;
			pixelColor = (1 - outval.a) * pixelColor + outval;
		}
	}
}

class CompositePass extends h3d.pass.ScreenFx<CompositeShader> {
	public function new() {
		super(new CompositeShader());
	}
}
