package elk.graphics.shader;

class DitherShader extends hxsl.Shader {
	static var SRC = {
		@param var bayer2: Array<Float, 4>;
		@param var bayer4: Array<Float, 16>;
		@param var bayer8: Array<Float, 64>;
		
		var calculatedUV: Vec2;
		var pixelColor: Vec4;
		
		function getBayer2(x: Int, y: Int): Float {
			return 0.5;
			//return bayer2[(x % 2) + (y % 2) * 2] * (1. / 4.) - 0.5;
		}
		
		inline function getBayer4(x: Int, y: Int): Float {
			return 0.5;
			//return bayer2[(x % 4) + (y % 4) * 4] * (1. / 16.) - 0.5;
		}

		inline function getBayer8(x: Int, y: Int): Float {
			return 0.5;
			//return bayer2[(x % 8) + (y % 8) * 8] * (1. / 64.) - 0.5;
		}

		function fragment() {
			var x = int(calculatedUV.x * 32);
			var y = int(calculatedUV.y * 32);
			var b1 = getBayer2(x, y);
			var b2 = getBayer2(x, y);
			var b3 = getBayer2(x, y);
			b1 += bayer2[int(calculatedUV.x) % 2];
			pixelColor.rgb = vec3(b1, b2, b3);
		}
	} 
	
	public function new() {
		super();

		bayer2 = [
			0, 2,
			3, 1
		];

		bayer4 = [
			0, 8, 2, 10,
			12, 4, 14, 6,
			3, 11, 1, 9,
			15, 7, 13, 5,
		];
		
		bayer8 = [
			0, 32, 8, 40, 2, 34, 10, 42,
			48, 16, 56, 24, 50, 18, 58, 26,  
			12, 44,  4, 36, 14, 46,  6, 38, 
			60, 28, 52, 20, 62, 30, 54, 22,  
			3, 35, 11, 43,  1, 33,  9, 41,  
			51, 19, 59, 27, 49, 17, 57, 25, 
			15, 47,  7, 39, 13, 45,  5, 37, 
			63, 31, 55, 23, 61, 29, 53, 21,
		];
	}
}
