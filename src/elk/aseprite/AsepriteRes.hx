package elk.aseprite;

import format.png.Reader;
import elk.graphics.Animation;
import h3d.mat.Texture;

class AsepriteRes extends hxd.res.Image {
	var imgPath : String;
	var aseData : AnimationData;
	var tiles : Array<h2d.Tile>;

	public function new(entry) {
		super(entry);
		imgPath = haxe.io.Path.directory(entry.path) + '/generated/' + haxe.io.Path.withExtension(entry.name, 'png');
		tiles = [];
	}

	public function replaceTile(rootTile : h2d.Tile, data : AnimationData) {
		data.rootTile = rootTile;
		generateFrameTiles(data);
	}

	function extractAnimationData() {
		var bb = new haxe.io.BytesInput(entry.getBytes());
		new Reader(bb).read();
		bb.bigEndian = false;
		return AnimationData.load(bb);
	}

	public function toAseData() {
		if( aseData != null ) {
			return aseData;
		}

		aseData = extractAnimationData();
		replaceTile(toTile(), aseData);

		if( hxd.res.Resource.LIVE_UPDATE ) {
			watch(refresh);
		}

		return aseData;
	}

	function refresh() {
		var newData : AnimationData = extractAnimationData();
		tex.dispose();
		tex = null;
		inf = null;
		replaceTile(toTile(), newData);
		aseData.copyFrom(newData);

		watch(refresh);
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
			var tile = data.rootTile.sub(frame.x, frame.y, frame.w, frame.h, dx, dy);
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
}
