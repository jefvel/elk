package elk.aseprite;

import elk.graphics.Animation;
import h3d.mat.Texture;

class AsepriteRes extends hxd.res.Resource {
	var imgPath : String;
	var rootTile : h2d.Tile;
	var aseData : AnimationData;
	var tiles : Array<h2d.Tile>;

	public function new(entry) {
		super(entry);
		imgPath = haxe.io.Path.directory(entry.path) + '/generated/' + haxe.io.Path.withExtension(entry.name, 'png');
		tiles = [];
	}

	public function replaceTile(rootTile : h2d.Tile, data : AnimationData) {
		this.rootTile = rootTile;
		data.rootTile = rootTile;
		generateFrameTiles(data);
	}

	function toImage() : hxd.res.Image {
		#if debug
		toAseData();
		#end
		return hxd.res.Loader.currentInstance.loadCache(imgPath, hxd.res.Image);
	}

	public function toAseData() {
		if( aseData != null ) {
			return aseData;
		}

		aseData = AnimationData.load(entry);
		if( rootTile == null ) {
			replaceTile(toTile(), aseData);
		}

		if( hxd.res.Resource.LIVE_UPDATE ) {
			watch(refresh);
		}

		return aseData;
	}

	function refresh() {
		haxe.Timer.delay(() -> {
			var newData : AnimationData = AnimationData.load(entry);
			replaceTile(toTile(), newData);
			aseData.copyFrom(newData);
		}, 100);
	}

	public function toAnimation() {
		var data = toAseData();
		return new Animation(data);
	}

	public function toSprite(?p : h2d.Object) {
		return new elk.graphics.Sprite(toAnimation(), p);
	}

	function generateFrameTiles(data : AnimationData) {
		for (i in 0...data.frames.length) {
			var frame = data.frames[i];
			var dx = frame.dx;
			var dy = frame.dy;
			var tile = rootTile.sub(frame.x, frame.y, frame.w, frame.h, dx, dy);
			frame.tile = tile;
			frame.slices = getSlicesForFrame(i);
		}
	}

	function getSlicesForFrame(frame : Int) {
		var slices = new Map<String, elk.aseprite.AnimationData.AnimationSliceKey>();
		var empty = true;
		for (name => slice in aseData.slices) {
			for (s in slice.keys) {
				if( s.frame == frame ) {
					slices[name] = s;
					empty = false;
					break;
				}
			}
		}

		if( empty ) return null;

		return slices;
	}

	public function toTile() : h2d.Tile {
		return toImage().toTile();
	}

	public function toTexture() : h3d.mat.Texture {
		return toImage().toTexture();
	}
}
