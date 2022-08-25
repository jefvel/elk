package elk.graphics.pass;

import h3d.pass.ScreenFx;
import h3d.shader.ScreenShader;

class RetroShader extends ScreenShader {

	static var SRC = {

		@param var cameraInverseViewProj : Mat4;

		@param var res: Vec2;
		@param var windowRes: Vec2;
		@param var maskPower: Float = 1.0;
		@param var noisePower: Float = 1.0;
		
		@param var waviness: Float = 0.;
		
		@param var time: Float;
		
		@param var perlinTex: Sampler2D;

		@param var texture : Sampler2D;
		@param var depthTexture : Sampler2D;
		@param @const var Quality : Int;
		@param @const var isDepth : Bool;
		@param var values : Array<Float,Quality>;
		@param var offsets : Array<Float,Quality>;
		@param var pixel : Vec2;

		@param var sharpness: Float = 0.01;

		@const var hasFixedColor : Bool;
		@const var smoothFixedColor : Bool;
		@param var fixedColor : Vec4;

		@param @const var isDepthDependant : Bool;
		@param @const var hasNormal : Bool;
		@param var normalTexture : Sampler2D;

		@param var pixelSize: Float = 2.0;

		// Hardness of scanline.
		//  -8.0 = soft
		// -16.0 = medium
		@param var hardScan: Float=-7.0;

		// Hardness of pixels in scanline.
		// -2.0 = soft
		// -4.0 = hard
		@param var hardPix: Float=-4.0;

		// Hardness of short vertical bloom.
		//  -1.0 = wide to the point of clipping (bad)
		//  -1.5 = wide
		//  -4.0 = not very wide at all
		@param var hardBloomScan: Float=-1.5;

		// Hardness of short horizontal bloom.
		//  -0.5 = wide to the point of clipping (bad)
		//  -1.0 = wide
		//  -2.0 = not very wide at all
		@param var hardBloomPix: Float=-2.0;

		// Amount of small bloom effect.
		//  1.0/1.0 = only bloom
		//  1.0/16.0 = what I think is a good amount of small bloom
		//  0.0     = no bloom
		@param var bloomAmount: Float = 1.0;

		// Amount of shadow mask.
		@param var maskDark: Float=0.98;
		@param var maskLight: Float=1.;
		
		function ToSrgb1(c: Float): Float {return(c<0.0031308?c*12.92:1.055*pow(c,0.41666)-0.055);}
		function ToSrgb(c:Vec3): Vec3{return vec3(ToSrgb1(c.r),ToSrgb1(c.g),ToSrgb1(c.b));}


		function ToLinear1(c: Float): Float {
			return (c <= 0.04045) ? c/12.92 : pow((c+0.055)/1.055,2.4);
		}

		function ToLinear(c: Vec3): Vec3{
			return vec3(ToLinear1(c.r),ToLinear1(c.g),ToLinear1(c.b));
		}

		// Nearest emulated sample given floating point position and texel offset.
		// Also zero's off screen.
		function Fetch(pos: Vec2, off: Vec2): Vec3 {
			var resPos = floor(pos*res+off)/res;
			return (max(abs(resPos.x-0.5),abs(resPos.y-0.5))>0.5) ? vec3(0, 0, 0) : ToLinear(texture.get(resPos.xy).rgb);
		}

		// Distance in emulated pixels to nearest texel.
		function Dist(pos: Vec2): Vec2{
			var resPos = pos*res;
			return -((resPos-floor(resPos))-vec2(0.5));
		}
			
		// 1D Gaussian.
		function Gaus(pos: Float, scale: Float):Float {
			return exp2(scale*pos*pos);
		}

		// 3-tap Gaussian filter along horz line.
		function Horz3(pos: Vec2, off: Float): Vec3{
			var b = Fetch(pos, vec2(-1.0,off));
			var c=Fetch(pos,vec2( 0.0,off));
			var d=Fetch(pos,vec2( 1.0,off));
			var dst=Dist(pos).x;
			// Convert distance to weight.
			var scale=hardPix;
			var wb=Gaus(dst-1.0,scale);
			var wc=Gaus(dst+0.0,scale);
			var wd=Gaus(dst+1.0,scale);
			// Return filtered sample.
			return (b*wb+c*wc+d*wd)/(wb+wc+wd);
		}

		// 5-tap Gaussian filter along horz line.
		function Horz5(pos: Vec2, off: Float): Vec3{
			var a=Fetch(pos,vec2(-2.0,off));
			var b=Fetch(pos,vec2(-1.0,off));
			var c=Fetch(pos,vec2( 0.0,off));
			var d=Fetch(pos,vec2( 1.0,off));
			var e=Fetch(pos,vec2( 2.0,off));
			var dst=Dist(pos).x;
			// Convert distance to weight.
			var scale=hardPix;
			var wa=Gaus(dst-2.0,scale);
			var wb=Gaus(dst-1.0,scale);
			var wc=Gaus(dst+0.0,scale);
			var wd=Gaus(dst+1.0,scale);
			var we=Gaus(dst+2.0,scale);
			// Return filtered sample.
			return (a*wa+b*wb+c*wc+d*wd+e*we)/(wa+wb+wc+wd+we);
		}

		// 7-tap Gaussian filter along horz line.
		function Horz7(pos: Vec2, off: Float): Vec3{
			var a=Fetch(pos,vec2(-3.0,off));
			var b=Fetch(pos,vec2(-2.0,off));
			var c=Fetch(pos,vec2(-1.0,off));
			var d=Fetch(pos,vec2( 0.0,off));
			var e=Fetch(pos,vec2( 1.0,off));
			var f=Fetch(pos,vec2( 2.0,off));
			var g=Fetch(pos,vec2( 3.0,off));
			var dst=Dist(pos).x;
			// Convert distance to weight.
			var scale=hardBloomPix;
			var wa=Gaus(dst-3.0,scale);
			var wb=Gaus(dst-2.0,scale);
			var wc=Gaus(dst-1.0,scale);
			var wd=Gaus(dst+0.0,scale);
			var we=Gaus(dst+1.0,scale);
			var wf=Gaus(dst+2.0,scale);
			var wg=Gaus(dst+3.0,scale);
			// Return filtered sample.
			return (a*wa+b*wb+c*wc+d*wd+e*we+f*wf+g*wg)/(wa+wb+wc+wd+we+wf+wg);
		}

		// Return scanline weight.
		function Scan(pos: Vec2, off: Float): Float {
			var dst=Dist(pos).y;
			return Gaus(dst+off,hardScan);
		}

		// Return scanline weight for bloom.
		function BloomScan(pos:Vec2,off: Float): Float {
			var dst=Dist(pos).y;
			return Gaus(dst+off,hardBloomScan);
		}

		// Allow nearest three lines to effect pixel.
		function Tri(pos:Vec2): Vec3{
			var a=Horz3(pos,-1.0);
			var b=Horz5(pos, 0.0);
			var c=Horz3(pos, 1.0);

			var wa=Scan(pos,-1.0);
			var wb=Scan(pos, 0.0);
			var wc=Scan(pos, 1.0);

			return a*wa + b*wb + c*wc;
		}
		function random (st:Vec2): Float {
			return fract(sin(dot(st.xy,
								 vec2(12.9898,78.233)))
						 * 43758.5453123);
		}
		
		// 2D Noise based on Morgan McGuire @morgan3d
		// https://www.shadertoy.com/view/4dS3Wd
		function noise (st:Vec2): Float {
			var i = floor(st);
			var f = fract(st);
		
			// Four corners in 2D of a tile
			var a = random(i);
			var b = random(i + vec2(1.0, 0.0));
			var c = random(i + vec2(0.0, 1.0));
			var d = random(i + vec2(1.0, 1.0));
		
			// Smooth Interpolation
		
			// Cubic Hermine Curve.  Same as SmoothStep()
			var u = f*f*(3.0-2.0*f);
			// u = smoothstep(0.,1.,f);
		
			// Mix 4 coorners percentages
			return mix(a, b, u.x) +
					(c - a)* u.y * (1.0 - u.x) +
					(d - b) * u.x * u.y;
		}


		function Warp(p: Vec2, waveScale: Float): Vec2 {
			var s = 1.1;
			var warp = vec2(s / (512.0), s / (192.0));
			var pos = p * 2.0 - 1.0;
			pos *= vec2(1.0 + (pos.y * pos.y) * warp.x, 1.0 + (pos.x * pos.x) * warp.y);

			pos.x += sin(p.y * res.y / 8. + time) * waviness * 0.01 * waveScale;
			pos.x += sin(time * 300) * waviness * 0.08 * waveScale;

			return pos * 0.5 + 0.5;
		}

		// Stretched VGA style shadow mask (same as prior shaders).
		function Mask(pos: Vec2): Vec3{
			var resPos = pos * 2.1;
			//resPos.x += pos.y;// / 3.0;
			var mask=vec3(maskDark,maskDark,maskDark);
			resPos=fract(vec2(resPos.x/9.0, resPos.y / 18.));
			if(resPos.x<0.333) mask.r=maskLight;
			else if(resPos.x<0.666)mask.g=maskLight;
			else mask.b=maskLight;

			// if (resPos.y < 0.333) mask *= 0.99;

			return mask;
		} 

		function fragment() {
			var color = vec4(0, 0, 0, 0);
			var sPerPixel = 1 / res.xy;
			var sPerWindowPixel = 1 / windowRes.xy;
			var vy = vec2(0, -sPerWindowPixel.y * 1.0);
			var blur = 0.2;
			var green = vec4(0, blur, 0., 0);
			var norm = vec4(1, 1 - blur, 1., 1);
			
			var newUv = input.uv;
			
			// Sharpness
			var sharpnessCol = vec4(0);
			sharpnessCol += texture.get(Warp(newUv, 1.0)) * (8 + 1);
			
			var neighbors = vec4(0);
			var neighborCoeff = -1;

			neighbors += texture.get(Warp(newUv + sPerWindowPixel * vec2( 1, 0), 1));
			neighbors += texture.get(Warp(newUv + sPerWindowPixel * vec2(-1, 0), 1));
			neighbors += texture.get(Warp(newUv + sPerWindowPixel * vec2( 0, 1), 1));
			neighbors += texture.get(Warp(newUv + sPerWindowPixel * vec2( 0,-1), 1));

			neighbors += texture.get(Warp(newUv + sPerWindowPixel * vec2(-1,-1), 1));
			neighbors += texture.get(Warp(newUv + sPerWindowPixel * vec2( 1,-1), 1));
			neighbors += texture.get(Warp(newUv + sPerWindowPixel * vec2(-1, 1), 1));
			neighbors += texture.get(Warp(newUv + sPerWindowPixel * vec2( 1, 1), 1));

			sharpnessCol += neighbors * neighborCoeff;
			sharpnessCol.a = 1.0;
			
			newUv += (perlinTex.get(mod(newUv * sPerWindowPixel * 1024, vec2(1))).rr - vec2(0.5)) * sPerWindowPixel * 2;

			// Blur
			@unroll for( i in -Quality + 1...Quality){
				var tUv = mix(newUv, Warp(newUv, 1.0), 1 - maskPower) + pixel * offsets[i < 0 ? -i : i] * i;
				var modUv = mod(tUv, sPerWindowPixel);

				// Uncomment to fix pixels
				// tUv -= modUv * maskPower;

				//tUv = Warp(tUv);
				//color.rgb = vec3(distance(modUv, sPerWindowPixel * 0.5) / length(sPerWindowPixel));
				//color.rgb = texture.get(tUv).rgbv;
				color += texture.get(tUv + sPerWindowPixel * 0.5 * maskPower) * values[i < 0 ? -i : i] * norm;
				color += texture.get(tUv + sPerWindowPixel * 0.5 * maskPower + vy) * values[i < 0 ? -i : i] * green;
			}

			
			color = mix(color, sharpnessCol, sharpness);

			var pos = Warp(newUv, 0.);
			var mask = Mask(pos * windowRes.xy);
			//var color = Tri(pos);
			
			var scale = smoothstep(0.999, 1, abs(pos - vec2(0.5)) * 2);
			var s = 1 - (1 - maskPower) * max(scale.x, scale.y);
			//if (pos.y > 1) s = 0;
			
			// var color = color.rgb * mask;

			//pixelColor.rgb = color.rgb * mask;

			pixelColor = vec4(color.rgb * mix(vec3(1), mask, maskPower), 1.0) + vec4(0.03, 0.03, 0.04, 0);


			if (noisePower > 0) {
				var noisePos = pos * windowRes.xy;
				var t = fract(time * 100) * windowRes.y;
				noisePos.y += t;
				var noise = 0.015 * vec3(noise(noisePos / 3.0), noise(noisePos / 3.0 + 100), noise(noisePos / 3.0 + 400));
				pixelColor.rgb -= noise * noisePower;
			}

			pixelColor.rgb *= s;
		}
	}
}


@ignore("shader")
class RetroPass extends ScreenFx<RetroShader> {
	/**
		How far in pixels the blur will go.
	**/
	public var radius(default,set) : Float;

	/**
		How much the blur increases or decreases the color amount (default = 1)
	**/
	public var gain(default,set) : Float;

	/**
		Set linear blur instead of gaussian (default = 0).
	**/
	public var linear(default, set) : Float;

	/**
		Adjust how much quality/speed tradeoff we want (default = 1)
	**/
	public var quality(default,set) : Float;

	var values : Array<Float>;
	var offsets : Array<Float>;
	
	public var waviness : Float = 0.;
	public var sharpness: Float = 0.04;
	public var noise(get, set): Float;
	
	function set_noise(s) return shader.noisePower = s;
	function get_noise() return shader.noisePower;

	public function new( radius = 1., gain = 1., linear = 0., quality = 1. ) {
		var shader = new RetroShader();

		var tex = hxd.Res.img.proc.perlin.toTexture();
		shader.perlinTex = tex;

		super(shader);

		this.radius = radius;
		this.quality = quality;
		this.gain = gain;
		this.linear = linear;
	}

	function set_radius(r) {
		if( radius == r )
			return r;
		values = null;
		return radius = r;
	}

	function set_quality(q) {
		if( quality == q )
			return q;
		values = null;
		return quality = q;
	}

	function set_gain(s) {
		if( gain == s )
			return s;
		values = null;
		return gain = s;
	}

	function set_linear(b) {
		if( linear == b )
			return b;
		values = null;
		return linear = b;
	}

	function gauss( x:Float, s:Float ) : Float {
		if( s <= 0 ) return x == 0 ? 1 : 0;
		var sq = s * s;
		var p = Math.pow(2.718281828459, -(x * x) / (2 * sq));
		return p / Math.sqrt(2 * Math.PI * sq);
	}

	function calcValues() {
		values = [];
		offsets = [];

		var tot = 0.;
		var qadj = hxd.Math.clamp(quality) * 0.7 + 0.3;
		var width = radius > 0 ? Math.ceil(hxd.Math.max(radius - 1, 1) * qadj / 2) : 0;
		var sigma = Math.sqrt(radius);
		for( i in 0...width + 1 ) {
			var i1 = i * 2;
			var i2 = i == 0 ? 0 : i * 2 - 1;
			var g1 = gauss(i1, sigma);
			var g2 = gauss(i2, sigma);
			var g = g1 + g2;
			values[i] = g;
			offsets[i] = i == 0 ? 0 : (g1 * i1  + g2 * i2) / (g * i * Math.sqrt(qadj));
			tot += g;
			if( i > 0 ) tot += g;
		}

		// eliminate too low contributing values
		var minVal = values[0] * (0.01 / qadj);
		while( values.length > 2 ) {
			var last = values[values.length-1];
			if( last > minVal ) break;
			tot -= last * 2;
			values.pop();
		}

		tot /= gain;
		for( i in 0...values.length )
			values[i] /= tot;

		if( linear > 0 ) {
			var m = gain / (values.length * 2 - 1);
			for( i in 0...values.length ) {
				values[i] = hxd.Math.lerp(values[i], m, linear);
				offsets[i] = hxd.Math.lerp(offsets[i], i == 0 ? 0 : (i * 2 - 0.5) / (i * qadj), linear);
			}
		}
	}

	public function getKernelSize() {
		if( values == null ) calcValues();
		return radius <= 0 ? 0 : values.length * 2 - 1;
	}

	public function apply( ctx : h3d.impl.RenderContext, src : h3d.mat.Texture, ?output : h3d.mat.Texture ) {

		if( radius <= 0 && shader.fixedColor == null ) {
			if( output != null ) h3d.pass.Copy.run(src, output);
			return;
		}
		
		if( output == null ) output = src;
		if( values == null ) calcValues();

		//src.filter = Nearest;
		
		var tmp = ctx.textures.allocTarget(src.name+"RetroTmp", src.width, src.height, false, src.format);
		
		shader.waviness = 0;
		shader.sharpness = 0;
		
		var w = engine.width;
		var h = engine.height;

		shader.windowRes.set(
			w,
			h
		);
		
		var pixelSize = Elk.instance.pixelSize;

		shader.res.set(
			w / pixelSize,
			h / pixelSize
		);

		shader.pixelSize = pixelSize;

		//shader.bloomAmount = 0; //1 / 16;

		shader.Quality = values.length;
		shader.values = values;
		shader.offsets = offsets;

		shader.texture = src;
		shader.maskPower = 1.0;

		shader.pixel.set(1 / src.width, 0);
		var outDepth = output.depthBuffer;
		output.depthBuffer = null;

		engine.pushTarget(tmp, 0);
		render();
		engine.popTarget();
		output.depthBuffer = outDepth;

		shader.texture = tmp;

		shader.pixelSize = 1.;
		shader.maskPower = 0.0;
		shader.time = ctx.time;
		
		shader.waviness = waviness;
		shader.sharpness = sharpness;

		shader.pixel.set(0, 1 / src.height);
		var outDepth = output.depthBuffer;
		output.depthBuffer = null;

		engine.pushTarget(output, 0);
		render();
		engine.popTarget();

		output.depthBuffer = outDepth;
	}
}