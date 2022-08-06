package elk.aseprite;

import h3d.mat.Texture;

class AsepriteRes extends hxd.res.Resource {
	var imgPath: String;
	public function new(entry) {
		super(entry);
		imgPath = haxe.io.Path.directory(entry.path) + '/.generated/' + haxe.io.Path.withExtension(entry.name, 'png');
	}

	function toImage(): hxd.res.Image {
		return hxd.res.Loader.currentInstance.loadCache(imgPath, hxd.res.Image);
	}
	
	public function toAseData() {
		var res: AsepriteData = haxe.Unserializer.run(entry.getText());
		return res;
	}
	
	public function toTile(): h2d.Tile {
		return toImage().toTile();
	}
	
	public function toTexture(): h3d.mat.Texture {
		return toImage().toTexture();
	}
}