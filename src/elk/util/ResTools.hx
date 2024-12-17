package elk.util;

// taken from https://github.com/Yanrishatum/heeps/blob/master/cherry/tools/ResTools.hx
import hxd.fs.FileInput;
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.crypto.Base64;

class ResTools {
	/**
		Equivalent to `Res.initPak` but also works with JS.

		Example usage:
		```haxe
		// In your App class
		override function loadAssets(onLoaded:() -> Void)
		{
		  ResTools.initPakAuto(onLoaded, (p) -> trace(p));
		}
		```

		@param file Optional resource folder path. Defaults to value in `resourcesPath` or `res`.
		@param onReady `Void->Void` Required callback when resources are loaded. Because JS can't load pak instantly,
		it is done asynchronously and callback is called when Res is initialised.
		Called instantly on non-JS target.
		@param onProgress `Float->Void` Optional callback for loading progress. Passed value is a percentile from 0 to 1.
		Never called on non-JS target.
	**/
	public static macro function initPakAuto(?file:String, onReady:ExprOf<Void->Void>, ?onProgress:ExprOf<Float->Void>) {
		if (file == null)
			file = haxe.macro.Context.definedValue("resourcesPath");
		if (file == null)
			file = "res";

		var build_dir = haxe.macro.Context.definedValue('build_dir');
		var root_dir = build_dir != null ? '$build_dir/' : '';

		// TODO: Config stuff
		var pak_infos = new Map<String, {
			hash:String,
			size:Int,
		}>();

		#if (!display || use_pak)
		hxd.fmt.pak.Build.make(sys.FileSystem.fullPath(file), '$root_dir$file', true);
		pak_infos = generate_pak_hashes();
		#end

		if (haxe.macro.Context.definedValue("target.name") == "js") {
			var maxPaks = 1;
			while (true) {
				var existing_pak_name = root_dir + file + maxPaks + ".pak";
				if (!sys.FileSystem.exists(existing_pak_name))
					break;
				maxPaks++;
			}

			return macro {
				var file = $v{file};
				var pak_infos = $v{pak_infos};
				var pak = new hxd.fmt.pak.FileSystem();
				var pak_index = 0;

				inline function get_url(file:String) {
					var info = pak_infos.get(file);
					var hash = info.hash;
					return file + ".pak" + (hash != null ? '?h=${hash}' : '');
				}

				var loader = new hxd.net.BinaryLoader(get_url(file));

				var total_size = 0;
				for (info in $v{pak_infos}) {
					total_size += info.size;
				}

				var on_progress = $onProgress;
				var total_loaded = 0;
				if (on_progress != null)
					loader.onProgress = (c:Int, m:Int) -> {
						var progress = (total_loaded + c) / total_size;
						on_progress(progress);
					};

				loader.onLoaded = (data) -> {
					total_loaded += data.length;
					pak.addPak(new hxd.fmt.pak.FileSystem.FileInput(data));
					if (++pak_index == $v{maxPaks}) {
						hxd.Res.loader = new hxd.res.Loader(pak);
						${onReady}();
					} else {
						@:privateAccess loader.url = get_url('$file$pak_index');
						loader.load();
					}
				}
				loader.onError = (e) -> {
					throw e;
					// if (i == 0) throw e;
					// else {
					//   hxd.Res.loader = new hxd.res.Loader(pak);
					//   ${onReady}();
					// }
				}
				loader.load();
			}
		} else {
			return macro {
				var file = $v{file};
				var pak = new hxd.fmt.pak.FileSystem();
				pak.loadPak(file + ".pak");
				var i = 1;
				while (true) {
					if (!hxd.File.exists(file + i + ".pak"))
						break;
					pak.loadPak(file + i + ".pak");
					i++;
				}
				hxd.Res.loader = new hxd.res.Loader(pak);
				${onReady}();
			}
		}
	}

	#if sys
	public static function generate_pak_hashes() {
		var pak_hashes = new Map<String, {
			hash:String,
			size:Int,
		}>();
		var build_dir = haxe.macro.Context.definedValue('build_dir');
		if (build_dir == null || build_dir == "") {
			trace('no build_dir defined.');
			return pak_hashes;
		}

		var build_files = sys.FileSystem.readDirectory(build_dir);
		for (file in build_files) {
			var file_path = new haxe.io.Path(sys.FileSystem.absolutePath('$build_dir/$file'));
			if (sys.FileSystem.isDirectory(file_path.toString()))
				continue;

			if (file_path.ext != 'pak')
				continue;
			var bytes = sys.io.File.getBytes(file_path.toString());
			var md5 = haxe.crypto.Md5.make(bytes);
			pak_hashes.set(file_path.file, {
				hash: Base64.encode(md5),
				size: bytes.length,
			});
		}

		return pak_hashes;
	}
	#end
}
