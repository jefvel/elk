package elk.buildutil;

import elk.aseprite.AsepriteConvert;
import elk.res.ConvertBinJSON;

class Config {
	static function initConfig() {
		hxd.res.Config.ignoredExtensions["blend"] = true;
		hxd.res.Config.ignoredExtensions["blend1"] = true;
		// hxd.res.Config.ignoredExtensions["aseprite"] = true;
		hxd.res.Config.ignoredExtensions["wav.asd"] = true;

		// hxd.res.Config.addPairedExtension("aseprite", "png");

		// Files with the extension .tilesheet will be able to
		// be loaded using the TileSheetRes class.
		hxd.res.Config.extensions["aseprite,ase"] = "elk.aseprite.AsepriteRes";
	}
}
