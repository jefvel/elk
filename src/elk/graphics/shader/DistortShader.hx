package elk.graphics.shader;

class DistortShader extends h3d.shader.ScreenShader {
	static var SRC = {
		@param var texture : Sampler2D;
		@param var screenSize : Vec2;
		@global var time : Float;
		@param var mask : Sampler2D;
		@param var maskMatA : Vec3;
		@param var maskMatB : Vec3;
		@param var smoothAlpha : Bool;
		@param var bias : Float;
		@param var offset : Vec2;
		@:import h3d.shader.NoiseLib;
		function fragment() {
			noiseSeed = 3;
			var uv = vec2(calculatedUV);
			uv.x += time * 0.1;
			uv.y -= time * 0.12;
			var offset = sdnoise(uv).xy * 0.005;
			offset += sdnoise(uv * -10).xy * 0.0001;
			var pixel : Vec4 = texture.get(calculatedUV + offset);
			pixelColor = pixel;
		}
	}
}
