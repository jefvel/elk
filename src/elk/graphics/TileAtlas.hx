package elk.graphics;

import elk.util.RectPacker;
import h2d.Drawable;
import h2d.Object;
import h2d.Bitmap;
import h3d.mat.Texture;
import h2d.RenderContext;
import h2d.TileGroup;
import h2d.Tile;

private class TileRect implements elk.util.RectPacker.RectPackNode {
	public var object : Object;
	public var x : Int;
	public var y : Int;
	public var width : Int;
	public var height : Int;

	public function new() {}
}

class TileAtlas extends Tile {
	static final DEFAULT_MAX_WIDTH = 1024 << 2;
	static final DEFAULT_MAX_HEIGHT = 1024 << 2;

	var packer : RectPacker<TileRect>;

	var atlas_width = DEFAULT_MAX_WIDTH;
	var atlas_height = DEFAULT_MAX_HEIGHT;

	var atlas : Texture;

	var namedTiles : Map<String, Tile> = new Map();
	var tileList : Array<Tile> = [];

	public function new(max_width = 1024 << 2, max_height = 1024 << 2) {
		atlas_width = max_width;
		atlas_height = max_height;

		resetTexture();
		packer = new RectPacker(atlas_width, atlas_height);
		packer.autoResize = false;

		super(atlas, 0, 0, atlas_width, atlas_height);
	}

	function resetTexture() {
		if( atlas != null ) {
			atlas.dispose();
			atlas = null;
		}

		atlas = new Texture(atlas_width, atlas_height, [Target], RGBA);
		atlas.clear(0x000000, 0.0);
		this.innerTex = atlas;
	}

	function addObject(o : Object) {
		var b = o.getBounds();
		var rect = new TileRect();
		rect.object = o;
		rect.width = Std.int(b.width);
		rect.height = Std.int(b.height);
		packer.add(rect);

		o.x = rect.x;
		o.y = rect.y;
		o.drawTo(atlas);

		var res = sub(o.x, o.y, b.width, b.height);

		return res;
	}

	/**
	 * returns sub tile of atlas, null if non existent
	 * @param name 
	 */
	public function get_tile(name) {
		return namedTiles[name];
	}

	/**
	 * renders tile to atlas, and returns new sub tile of it
	 * @param tile 
	 * @param name 
	 */
	public function add_tile(tile : Tile, name) {
		if( namedTiles.exists(name) ) {
			return namedTiles[name];
		}

		var t = addObject(new Bitmap(tile));
		namedTiles[name] = t;

		return t;
	}
}
