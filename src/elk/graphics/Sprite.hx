package elk.graphics;

import h2d.Tile;
import h2d.RenderContext;
import h2d.Bitmap;

class Sprite extends Bitmap {
	public var animation: Animation;

	var lastTile: Tile = null;
	var dirty = false;
	
	public var originX(default, set) = 0;
	public var originY(default, set) = 0;

	public function new(animation: Animation, ?p) {
		super(null, p);
		this.animation = animation;
	}
	
	function refreshTile() {
		var frame = animation.currentFrame;
		var t = frame.tile;

		if (!dirty && t == lastTile) {
			return;
		}

		dirty = false;
		lastTile = t;

		this.tile = t;
		if (frame != null) {
			t.dx = frame.dx - originX;
			t.dy = frame.dy - originY;
		}
	}
	
	override function sync(ctx:RenderContext) {
		animation.update(ctx.elapsedTime);

		if (parent == null) {
			return;
		}

		refreshTile();
		super.sync(ctx);
	}
	
	inline function set_originX(o:Int) {
		if (o != originX)
			dirty = true;
		return originX = o;
	}

	inline function set_originY(o:Int) {
		if (o != originY)
			dirty = true;
		return originY = o;
	}
}