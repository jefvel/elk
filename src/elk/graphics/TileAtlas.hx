package elk.graphics;

import h2d.Drawable;
import h2d.Object;
import h2d.Bitmap;
import h3d.mat.Texture;
import h2d.RenderContext;
import h2d.TileGroup;
import h2d.Tile;

class TileAtlas extends Tile {
	static final DEFAULT_MAX_WIDTH = 1024 << 2;
	static final DEFAULT_MAX_HEIGHT = 1024 << 2;

	var atlas_width = DEFAULT_MAX_WIDTH;
	var atlas_height = DEFAULT_MAX_HEIGHT;

	var atlas:Texture;

	var namedTiles:Map<String, Tile> = new Map();
	var tileList:Array<Tile> = [];

	public function new(max_width = 1024 << 2, max_height = 1024 << 2) {
		atlas_width = max_width;
		atlas_height = max_height;

		resetTexture();
		super(atlas, 0, 0, atlas_width, atlas_height);
	}

	function resetTexture() {
		if (atlas != null) {
			atlas.dispose();
			atlas = null;
		}

		atlas = new Texture(atlas_width, atlas_height, [Target], RGBA);
		atlas.clear(0x000000, 0.0);
		this.innerTex = atlas;
	}

	var cx = 0;
	var cy = 0;
	var rowHeight = 0;

	function addObject(o:Object) {
		var b = o.getBounds();
		if (cx + b.width > atlas_width) {
			cx = 0;
			cy += rowHeight;
			rowHeight = 0;
		}

		if (b.height > rowHeight)
			rowHeight = Std.int(b.height);

		o.x = cx;
		o.y = cy;
		o.drawTo(atlas);

		var res = sub(cx, cy, b.width, b.height);

		cx += Std.int(b.width);

		return res;
	}

	/**
	 * skips to the next row in the packing
	 */
	function nextRow() {
		cx = 0;
		cy += rowHeight;
		rowHeight = 0;
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
	public function add_tile(tile:Tile, name) {
		if (namedTiles.exists(name)) {
			return namedTiles[name];
		}

		var t = addObject(new Bitmap(tile));
		namedTiles[name] = t;

		return t;
	}
}
