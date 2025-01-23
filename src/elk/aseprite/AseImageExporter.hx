package elk.aseprite;

import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import elk.aseprite.AsepriteData.AseDataFrame;

private class BitmapDataRect implements elk.util.RectPacker.RectPackNode {
	public var x : Int;
	public var y : Int;

	public var width : Int;
	public var height : Int;
	public var bitmap : hxd.BitmapData;

	public var offsetX = 0;
	public var offsetY = 0;

	public var frame : ase.Frame;

	public function new(w, h, d, ox, oy, f) {
		width = w;
		height = h;
		bitmap = d;
		offsetX = ox;
		offsetY = oy;
		frame = f;
	}
}

class AseImageExporter {
	public function new() {}

	public static function export(srcPath : String, destPath : String) {
		var srcDir = haxe.io.Path.directory(srcPath);
		var imageName = haxe.io.Path.withoutExtension(haxe.io.Path.withoutDirectory(srcPath));

		var fileBytes = sys.io.File.getBytes(srcPath);

		var file = ase.Ase.fromBytes(fileBytes);

		var tags = getAseTags(file);
		var slices = getAseSlices(file);

		for (chunk in file.firstFrame.chunks) {}
		var packer = new elk.util.RectPacker<BitmapDataRect>(32, 32);

		var frameIndex = 0;
		var tagFrameDurations = new Map<String, Int>();
		for (frame in file.frames) {
			for (tag in tags) {
				if( frameIndex >= tag.from && frameIndex <= tag.to ) {
					tag.duration += frame.duration;
					if( !tagFrameDurations.exists(tag.name) ) {
						tagFrameDurations.set(tag.name, frame.duration);
					} else {
						if( tagFrameDurations[tag.name] != frame.duration ) {
							tag.constantSpeed = false;
						}
					}
				}
			}

			var cel = frame.cels[0];
			var bytes = frame.cels[0].pixelData;
			var converted = haxe.io.Bytes.alloc(bytes.length);
			for (i in 0...Std.int(bytes.length / 4)) {
				var col = bytes.getInt32(i * 4);

				var R = (col & 0x000000ff);
				var G = (col & 0x0000ff00) >> 8;
				var B = (col & 0x00ff0000) >> 16;

				var A = cast(col & 0xff000000, UInt) >> 24;

				col = (B << 24) | (G << 16) | (R << 8) | A;

				converted.setInt32(i * 4, col);
			}

			var dat = new hxd.BitmapData(cel.width, cel.height);
			var pixls = new hxd.Pixels(cel.width, cel.height, bytes, hxd.PixelFormat.RGBA);

			dat.setPixels(pixls);
			packer.add(new BitmapDataRect(cel.width, cel.height, dat, cel.xPosition, cel.yPosition, frame));

			frameIndex++;
		}

		packer.refresh();
		var bmpD = new hxd.BitmapData(packer.width, packer.height);
		var info = new AsepriteData();

		for (tag in tags) info.tags[tag.name] = tag;
		for (slice in slices) info.slices[slice.name] = slice;

		info.width = file.width;
		info.height = file.height;

		var frames : Array<AseDataFrame> = [];

		info.frames = frames;

		for (cel in packer.nodes) {
			var dat = cel.bitmap;

			bmpD.draw(cel.x, cel.y, dat, 0, 0, cel.width, cel.height, None,);
			frames.push({
				x : cel.x,
				y : cel.y,
				w : cel.width,
				h : cel.height,
				dx : cel.offsetX,
				dy : cel.offsetY,
				duration : cel.frame.duration,
			});
		}

		var png = bmpD.toPNG();

		sys.io.File.saveBytes('$srcDir/generated/$imageName.png', png);
		info.writeToFile(destPath);
	}

	private static inline function readString(input : haxe.io.BytesInput) : String {
		var length = input.readUInt16();
		return input.readString(length);
	}

	private static inline function getAseSlices(file : ase.Ase) : Array<AsepriteData.AseDataSlice> {
		var slices = [];
		for (chunk in file.firstFrame.chunks) {
			if( chunk.header.type != ase.types.ChunkType.SLICE ) continue;
			var bytes = chunk.toBytes();

			var input = new haxe.io.BytesInput(bytes);
			input.bigEndian = false;

			var size = input.readInt32();
			var header = input.readUInt16();

			var sliceCount : UInt = input.readInt32();
			var flags : UInt = input.readInt32();
			var is9Patch = (flags & 1) != 0;
			var hasPivot = (flags & 2) != 0;
			input.readInt32(); // Reserved
			var name = readString(input);

			var slice : AsepriteData.AseDataSlice = {
				name : name,
				keys : [],
			}

			for (sliceIndex in 0...sliceCount) {
				var frameNumber : UInt = input.readInt32();
				var x = input.readInt32();
				var y = input.readInt32();
				var width : UInt = input.readInt32();
				var height : UInt = input.readInt32();

				if( is9Patch ) {
					var centerX = input.readInt32();
					var centerY = input.readInt32();
					var centerWidth : UInt = input.readInt32();
					var centerHeight : UInt = input.readInt32();
				}

				if( hasPivot ) {
					var relativePivotX = input.readInt32();
					var relativePivotY = input.readInt32();
				}

				slice.keys.push({
					frame : frameNumber,
					x : x,
					y : y,
					w : width,
					h : height,
				});
			}

			slices.push(slice);
		}

		return slices;
	}

	private static inline function getAseTags(file : ase.Ase) {
		var tags : Array<elk.aseprite.AsepriteData.AseDataTag> = [];
		for (chunk in file.firstFrame.chunks) {
			if( chunk.header.type != ase.types.ChunkType.TAGS ) continue;
			var bytes = chunk.toBytes();

			var input = new haxe.io.BytesInput(bytes);
			input.bigEndian = false;

			var size = input.readInt32();
			var header = input.readUInt16();

			var tagCount = input.readInt16();

			input.read(8); // Blank

			for (i in 0...tagCount) {
				var from = input.readUInt16();
				var to = input.readUInt16();
				var direction : elk.aseprite.AsepriteData.AnimationDirection = switch (input.readByte()) {
					case 0: Forward;
					case 1: Reverse;
					case 2: PingPong;
					case 3: PingPongReverse;
					default:
						Forward;
				}

				input.readUInt16(); // repeat

				input.read(6); // Empty
				input.read(3); // RGB value
				input.readByte(); // Empty

				var name = readString(input);

				var tag : elk.aseprite.AsepriteData.AseDataTag = {
					name : name,
					duration : 0,
					constantSpeed : true,
					from : from,
					to : to,
					direction : direction,
					repeat : !StringTools.startsWith(name, '_'),
				};

				tags.push(tag);

				if( input.position + 1 >= input.length ) break;
			}

			input.close();
		}

		return tags;
	}
}
