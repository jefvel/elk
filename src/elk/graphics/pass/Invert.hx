package elk.graphics.pass;

import h3d.pass.ScreenFx;

class InvertShader extends h3d.shader.ScreenShader {

	static var SRC = {

		@param var texture : Sampler2D;

		@const var useAlpha : Bool;

		@param var invertPower : Float;

		function apply( color : Vec4, mat : Mat4 ) : Vec4 {
			// by default we ignore alpha since it's not accurate 
			// in a render target because of alpha blending
			return useAlpha ? color * mat : vec4(color.rgb, 1.) * mat;
		}

		function fragment() {
			var color = texture.get(input.uv);
			var inverted = vec3(1,1,1) - color.rgb;
			color.rgb = mix(color.rgb, inverted, invertPower);
			output.color = color; 
		}
	};
}

class Invert extends ScreenFx<InvertShader> {

	public var invertPower(get, set) : Float;

	public function new( invertPower = 1.0 ) {
		super(new InvertShader());
		shader.invertPower = 1;
	}

	inline function get_invertPower() return shader.invertPower;
	inline function set_invertPower(p) return shader.invertPower = p;

	public function apply( src : h3d.mat.Texture, out : h3d.mat.Texture) {
		engine.pushTarget(out);
		shader.texture = src;
		render();
		engine.popTarget();
	}
}