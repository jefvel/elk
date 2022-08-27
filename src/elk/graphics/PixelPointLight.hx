package elk.graphics;

class PixelPointLight extends h3d.scene.fwd.Light {

	var pshader : elk.graphics.shader.PixelPointLightShader;
	public var params(get, set) : h3d.Vector;
	
	public var segments(get,set): Int;

static var idd = 0;
var iddd = 0;
	public function new(?parent) {
		pshader = new elk.graphics.shader.PixelPointLightShader();
		super(pshader, parent);
		iddd = idd++;
	}

	override function get_color() {
		return pshader.color;
	}

	override function set_color(v) {
		return pshader.color = v;
	}

	override function get_enableSpecular() {
		return pshader.enableSpecular;
	}

	override function set_enableSpecular(b) {
		return pshader.enableSpecular = b;
	}

	inline function get_params() {
		return pshader.params;
	}

	inline function set_params(p) {
		return pshader.params = p;
	}

	override function emit(ctx) {
		var lum = hxd.Math.max(hxd.Math.max(color.r, color.g), color.b);
		var p = params;
		// solve lum / (x + y.d + z.d²) < 1/128
		if( p.z == 0 ) {
			cullingDistance = (lum * 128 - p.x) / p.y;
		} else {
			var delta = p.y * p.y - 4 * p.z * (p.x - lum * 128);
			cullingDistance = (p.y + Math.sqrt(delta)) / (2 * p.z);
		}
		cullingDistance = 160;
		pshader.lightPosition.set(absPos._41, absPos._42, absPos._43);
		super.emit(ctx);
	}
	
	function set_segments(segs) {
		return pshader.segments = segs;
	}

	function get_segments() {
		return pshader.segments;
	}
}
