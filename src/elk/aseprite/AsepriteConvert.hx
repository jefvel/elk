package elk.aseprite;

#if (sys || nodejs)
class AsepriteConvert extends hxd.fs.Convert {
	static var asepritePath : String = null;

	function new() {
		super("aseprite,ase", "asedata"); // converts .aseprite files to .asedata
	}

	override function convert() {
		exportAsepriteFile(srcPath, dstPath);
	}

	static function exportAsepriteFile(srcPath : String, dstPath : String) {
		#if hl
		AseImageExporter.export(srcPath, dstPath);
		#else
		// Generate aseprite converter hl command line app, and delete it after conversion
		if( !sys.FileSystem.exists('ase.converter.hl') ) {
			Sys.command('haxe -hl ase.converter.hl -lib heaps -lib ase -lib elk -main elk.aseprite.AseImageExporter');
			haxe.macro.Context.onAfterGenerate(() -> sys.FileSystem.deleteFile('ase.converter.hl'));
		}

		Sys.command('hl ase.converter.hl "$srcPath" "$dstPath"');
		#end
	}

	// register the convert so it can be found
	static var _ = hxd.fs.Convert.register(new AsepriteConvert());
}
#end
