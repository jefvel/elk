package elk.buildutil;
import elk.aseprite.AsepriteData;

private typedef AsepriteFrame = {
	var duration: Int;
	var sourceSize: { w: Int, h: Int };
	var frame: { x: Int, y: Int, w: Int, h: Int };
}

private typedef AsepriteFrameTag = {
	var name: String;
	var from: Int;
	var to: Int;
	var direction: String;
}

private typedef AsepriteSliceKey = {
	var frame:Int;
	var bounds: { x: Int, y: Int, w: Int, h: Int};
}

private typedef AsepriteSlice = {
	var name: String;
	var color: String;
	var keys: Array<AsepriteSliceKey>;
}

private typedef AsepriteMeta = {
	var scale: Int;
	var frameTags: Array<AsepriteFrameTag>;
	var slices: Array<AsepriteSlice>;
}

private typedef AsepriteJsonFile = {
	var frames: Array<AsepriteFrame>;
	var meta: AsepriteMeta;
}

#if (sys || nodejs)
class AseConvert extends hxd.fs.Convert {
	static var asepritePath: String = null;
    function new() {
        super("aseprite,ase","asedata"); // converts .aseprite files to .asedata
    }

    static function getAsepritePath() {
		if (asepritePath != null) {
			return;
		}

    	final defaultAsePath = "C:/Program Files/Aseprite/Aseprite.exe";

        #if macro
        var def = haxe.macro.Context.definedValue("asepritePath");
        #else
        var def : String = null;
        #end

        if (def != null) {
            asepritePath = def;
        } else {
            asepritePath = switch (Sys.systemName()) {
                case "Windows": defaultAsePath;
                case "Mac": "/Applications/Aseprite.app/Contents/MacOS/aseprite";
                case "Linux": "aseprite";
                default: defaultAsePath;
            }
        }
    }

    override function convert() {
		//AsepriteConverter.convertAsepriteFile(srcPath, dstPath);
		getAsepritePath();

        var spacing = 1;
		
		var args = [];

        var input = '-b $srcPath';
        var jsonOutput = '--data $dstPath';
        var pngOutput = '--sheet $dstPath.png';
        var format = '--format json-array';
        var type = '--sheet-type packed';
        var pack = '--sheet-pack';
        var listTags = '--list-tags';
        var padding = '--shape-padding $spacing';
		var trim = '--trim';
        var slices = '--list-slices';
		
        var ignoreLayers = '';
        var layers = '';

		var srcDir = haxe.io.Path.directory(srcPath);
		var imageName = StringTools.replace(originalFilename, "aseprite", "png");

		var bytes = new haxe.io.BytesInput(sys.io.File.getBytes(srcPath));
		var size = bytes.readInt32();
		var num = bytes.readUInt16() == 0xA5E0;
		var frames = bytes.readUInt16();
		bytes.close();
		
		args = [
			'-b',
			srcPath,
			'--data', '$dstPath',
			'--sheet', '$srcDir/generated/$imageName',
			'--format', 'json-array',
        	'--list-tags',
			'--shape-padding', '$spacing',
        	'--list-slices',
		];
		
		function addArg(name: String, ?val: String) {
			args.push(name);
			if (val != null) {
				args.push(val);
			}
		}
		
		if (frames > 1) {
			addArg('--trim');
			addArg('--sheet-type', 'packed');
		}
		
		command(asepritePath, args);

		convertAsepriteJsonToAseData(dstPath);
    }
	
	function convertAsepriteJsonToAseData(jsonPath: String) {
		var data:AsepriteJsonFile  = haxe.Json.parse(sys.io.File.getContent(jsonPath));
		var res = new AsepriteData();
		var frames: Array<AseDataFrame> = [];
		var slices = new Map<String, AseDataSlice>();
		var tags = new Map<String, AseDataTag>();

		var w = 0;
		var h = 0;

		for (f in data.frames) {
			res.totalDuration += f.duration;

			res.width = f.sourceSize.w;
			res.height = f.sourceSize.h;

			var frame = f.frame;
			frames.push({
				x: frame.x,
				y: frame.y,
				w: frame.w,
				h: frame.h,
				duration: f.duration,
			});
		}
		
		if (data.meta.slices != null) {
			for (s in data.meta.slices) {
				slices.set(s.name, {
					name: s.name,
					keys: s.keys.map(k -> { 
						var res: AseDataSliceKey = {
							frame: k.frame,
							x: k.bounds.x,
							y: k.bounds.y,
							w: k.bounds.w,
							h: k.bounds.h,
						};

						return res;
					})
				});
			}
		}
		
		if (data.meta.frameTags != null) {
			for (t in data.meta.frameTags) {
				var tag: AseDataTag = {
					duration: 0,
					name: t.name,
					direction: switch (t.direction) {
						case "forward": Forward;
						case "backward": Backward;
						case "pingpong": PingPong;
						default: Forward;
					},
					from: t.from,
					to: t.to,
					constantSpeed: true,
				};
				
				var frameCount = tag.to - tag.from;
				var frameLength = frames[0].duration;
				
				for (i in 0...frameCount + 1) {
					var frameIndex = i + t.from;
					var frame = frames[frameIndex];
					
					if (frameLength != frame.duration) {
						tag.constantSpeed = false;
					}

					tag.duration += frame.duration;
				}
				
				tags.set(tag.name, tag);
			}
		}
		
		res.frames = frames;
		res.slices = slices;
		res.tags = tags;
		
		save(haxe.io.Bytes.ofString(haxe.Serializer.run(res)));
	}

    // register the convert so it can be found
    static var _ = hxd.fs.Convert.register(new AseConvert());
}
#end