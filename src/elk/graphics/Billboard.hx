package elk.graphics;

import h3d.scene.RenderContext;
import h3d.mat.Material;

class BillboardShader extends hxsl.Shader {
	static var SRC = {
		// Sprite size in world coords
		@param var spriteSize:Vec2;
		// Upper and lower uv coords
		@param var uvs:Vec4;
		// xy = origin, zw = tile offset
		@param var offset:Vec4;
		@param var tileSize:Vec2;
		// @param var texture : Sampler2D;
		@input var input:{
			var position:Vec3;
			var normal:Vec3;
			var uv:Vec2;
		};

		var relativePosition:Vec3;
		var transformedPosition:Vec3;
		var calculatedUV:Vec2;
		var pixelColor:Vec4;

		function __init__() {
			relativePosition.xz *= tileSize;
			relativePosition.xz += offset.zw;
		}

		function vertex() {
			var uv1 = uvs.xy;
			var uv2 = uvs.zw;
			var d = uv2 - uv1;
			calculatedUV = vec2(input.uv * d + uv1);
		}
	};
}

@:access(h2d.Tile)
class Billboard extends h3d.scene.Mesh {
	public var tile(default, set): h2d.Tile = null;
	
	public var originX(default, set) = 0.;
	public var originY(default, set) = 0.;
	
	var lastTile: h2d.Tile = null;

	var quad: Quad;
	
	public var animation: elk.graphics.Animation;
	
	var shader: BillboardShader;
	public function new(animation: elk.graphics.Animation, ?p) {
		this.animation = animation;

		quad = Quad.defaultQuad();

		material = Material.create(animation.tile.getTexture());
		material.textureShader.killAlpha = true;
		material.mainPass.culling = None;
		var shadow = material.getPass("shadow");
		shadow.culling = None;
		shader = new BillboardShader();
		material.mainPass.addShader(shader);
		
		dirty = true;
		refreshTile();
		
		super(quad, material, p);
	}

	var dirty = false;
	var ppu = 1;
	
	function refreshTile() {
		var t = animation.tile;

		if (!dirty && t == lastTile) {
			return;
		}

		var f = animation.currentFrame;

		dirty = false;
		lastTile = t;

		var u = t.u;
		var u2 = t.u2;
		var v = t.v;
		var v2 = t.v2;

		@:privateAccess
		var tileSheet = animation.data;

		var ox:Float = f.dx - originX * tileSheet.width;
		var oy:Float = (tileSheet.height * (1 - originY)) - t.height - f.dy;

		var s = shader;
		s.uvs.set(u, v, u2, v2);
		s.offset.set((originX) * ppu, (tileSheet.height - originY) * ppu, // Origin X and Y
			ox * ppu, oy * ppu);

		s.spriteSize.set(tileSheet.width * ppu, tileSheet.height * ppu);
		s.tileSize.set(t.width * ppu, t.height * ppu);
		
		shader.tileSize.set(f.w, f.h);

		material.texture = t.getTexture();
	}

	public function update(dt: Float) {
		animation.update(dt);
	}

	override function sync(ctx:RenderContext) {
		super.sync(ctx);
		refreshTile();
	}

	function set_tile(t) {
		return this.tile = t;
	}
	
	function set_originX(originX) {
		dirty = true;
		return this.originX = originX;
	}

	function set_originY(originY) {
		dirty = true;
		return this.originY = originY;
	}
}
