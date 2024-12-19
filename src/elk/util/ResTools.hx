package elk.util;

// taken from https://github.com/Yanrishatum/heeps/blob/master/cherry/tools/ResTools.hx
import haxe.macro.Compiler;
import hxd.fs.FileInput;
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.ExprTools;
import haxe.crypto.Base64;

typedef SubPakDefinition = {
	name:String,
	included_paths:Array<String>,
}

typedef PakAutoOptions = {
	?embedded_paths:Array<String>,
	?named_paks:Array<SubPakDefinition>,
	?res_configuration:String,
}

typedef PakInfo = {
	hash:String,
	name:String,
	size:Int,
}

class ResTools {
	private static var pak_fs:hxd.fmt.pak.FileSystem;
	private static var pak_infos:Map<String, PakInfo> = null;

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
	public static macro function initPakAuto(?file:String, onReady:ExprOf<Void->Void>, ?onProgress:ExprOf<Float->Void>, ?options:PakAutoOptions) {
		if (file == null)
			file = haxe.macro.Context.definedValue("resourcesPath");
		if (file == null)
			file = "res";

		// #if debug null #else haxe.macro.Context.definedValue('res_config') #end;

		var configuration = options?.res_configuration;
		var build_dir = haxe.macro.Context.definedValue('build_dir');
		var root_dir = build_dir != null ? '$build_dir/' : '';

		var options = elk.castle.PakDefinitions.get_cdb_pak_definitions();

		// TODO: Config stuff
		var pak_infos = new Map<String, PakInfo>();

		var excluded_paths = options?.embedded_paths ?? [];
		for (named_pak in options?.named_paks ?? []) {
			excluded_paths = excluded_paths.concat(named_pak.included_paths);
		}

		#if (!display || use_pak)
		sys.FileSystem.createDirectory('$root_dir');
		hxd.fmt.pak.Build.make(sys.FileSystem.fullPath(file), '$root_dir$file', false, {
			excludedPaths: excluded_paths,
			configuration: configuration,
		});

		for (named_pak in options?.named_paks ?? []) {
			hxd.fmt.pak.Build.make(sys.FileSystem.fullPath(file), '$root_dir${named_pak.name}', false, {
				includedPaths: named_pak.included_paths,
				configuration: configuration,
			});
		}
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
				var embedded_fs = hxd.fs.EmbedFileSystem.create(null, {
					includedPaths: $v{options?.embedded_paths},
					configuration: $v{configuration},
				});
				hxd.Res.loader = new hxd.res.Loader(embedded_fs);

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
					break;
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
						hxd.Res.loader = new hxd.res.Loader(new MultiFileSystem([pak, embedded_fs]));

						@:privateAccess ResTools.pak_fs = pak;
						@:privateAccess ResTools.pak_infos = $v{pak_infos};

						${onReady}();
					} else {
						@:privateAccess loader.url = get_url('$file$pak_index');
						loader.load();
					}
				}
				loader.onError = (e) -> {
					throw e;
				}
				loader.load();
			}
		} else {
			return macro {
				var embedded_fs = hxd.fs.EmbedFileSystem.create(null, {includedPaths: $v{options?.embedded_paths}});
				hxd.Res.loader = new hxd.res.Loader(embedded_fs);

				var file = $v{file};

				var root_dir = $v{root_dir};

				inline function get_file_path(file:String) {
					#if debug
					return '$root_dir/$file.pak';
					#else
					return '$file.pak';
					#end
				}

				var pak = new hxd.fmt.pak.FileSystem();
				pak.loadPak(get_file_path(file));
				var i = 1;
				while (true) {
					var path = get_file_path(file + i);
					if (!hxd.File.exists(path))
						break;
					pak.loadPak(path);
					i++;
				}

				hxd.Res.loader = new hxd.res.Loader(new MultiFileSystem([pak, embedded_fs]));

				@:privateAccess ResTools.pak_fs = pak;
				@:privateAccess ResTools.pak_infos = $v{pak_infos};
				${onReady}();
			}
		}
	}

	#if !macro
	public static function load_named_pak(id:elk.castle.CastleDB.Pak_configKind, on_loaded:Void->Void, ?on_progress:Float->Void, ?on_error:String->Void) {
		if (pak_infos == null || pak_fs == null)
			throw "Pak system not initialized or loaded yet.";

		var name = id.toString();
		var build_dir = Compiler.getDefine('build_dir');
		var root_dir = build_dir != null ? '$build_dir/' : '';

		var existing_pak_name = root_dir + name;
		var pak_info:PakInfo = null;
		for (p in pak_infos)
			if (p.name == name) {
				pak_info = p;
				break;
			}

		inline function get_url(file:String) {
			var hash = pak_info?.hash;
			return file + ".pak" + (hash != null ? '?h=${hash}' : '');
		}

		#if js
		var loader = new hxd.net.BinaryLoader(get_url(name));

		if (on_progress != null)
			loader.onProgress = (c:Int, m:Int) -> {
				var progress = c / m;
				on_progress(progress);
			};

		loader.onLoaded = (data) -> {
			pak_fs.addPak(new hxd.fmt.pak.FileSystem.FileInput(data));
			on_loaded();
		}
		loader.onError = (e) -> {
			if (on_error != null)
				on_error(e);
		}
		loader.load();
		#else
		inline function get_file_path(file:String) {
			#if debug
			return '$root_dir/$file.pak';
			#else
			return '$file.pak';
			#end
		}
		pak_fs.loadPak(get_file_path(name));
		on_loaded();
		#end
	}
	#end

	#if (sys && macro)
	public static function generate_pak_hashes() {
		var pak_hashes = new Map<String, PakInfo>();

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
			var hash = haxe.crypto.Sha1.make(bytes).toHex();
			pak_hashes.set(file_path.file, {
				hash: hash,
				size: bytes.length,
				name: file_path.file,
			});
		}

		return pak_hashes;
	}
	#end
}
