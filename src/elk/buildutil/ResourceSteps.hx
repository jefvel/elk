package elk.buildutil;

import haxe.macro.Context;

class ResourceSteps {
	static macro function init_build_dir() {
		if (Context.defined("display")) {
			return null;
		}

		var clean_paks = Context.definedValue('clean_paks') != null;

		var build_dir = Context.definedValue('build_dir');
		if (build_dir == null || build_dir == "") {
			trace('no build_dir defined.');
			return null;
		}

		if (!clean_paks) {
			return null;
		}

		trace('Cleaning paks...');
		var build_files = sys.FileSystem.readDirectory(build_dir);
		for (file in build_files) {
			var file_path = new haxe.io.Path(sys.FileSystem.absolutePath('$build_dir/$file'));
			if (sys.FileSystem.isDirectory(file_path.toString()))
				continue;

			if (file_path.ext == 'pak')
				sys.FileSystem.deleteFile(file_path.toString());
		}

		return null;
	}
}
