package elk.aseprite;

import ase.chunks.OldPaleteChunk;
import ase.types.ColorDepth;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import elk.aseprite.AsepriteData.AseDataFrame;

private class BitmapDataRect implements elk.util.RectPacker.RectPackNode {
	public var index : Int;
	public var x : Int;
	public var y : Int;

	public var width : Int;
	public var height : Int;
	public var bitmap : hxd.BitmapData;

	public var offsetX = 0;
	public var offsetY = 0;

	public var frame : ase.Frame;

	public function new(i, w, h, d, ox, oy, f) {
		index = i;
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
		var palette = getAsePalette(file);
		for (p in palette) {
			var b = haxe.io.Bytes.alloc(4);
			b.setInt32(0, p);
			// trace(b.toHex());
		}

		var colorDepth = file.colorDepth;

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
			var width = 0;
			var height = 0;
			var yPos = 0;
			var xPos = 0;
			var converted : haxe.io.Bytes;

			if( cel != null ) {
				width = cel.width;
				height = cel.height;
				xPos = cel.xPosition;
				yPos = cel.yPosition;
				converted = haxe.io.Bytes.alloc(width * height * 4);
				var bytes = cel.pixelData;
				var r = new haxe.io.BytesInput(cel.pixelData);
				r.bigEndian = false;
				if( colorDepth == BPP32 ) {
					for (i in 0...Std.int(bytes.length / 4)) {
						var col = bytes.getInt32(i * 4);

						var R = (col & 0x000000ff);
						var G = (col & 0x0000ff00) >> 8;
						var B = (col & 0x00ff0000) >> 16;

						var A = cast(col & 0xff000000, UInt) >> 24;

						col = (B << 24) | (G << 16) | (R << 8) | A;

						converted.setInt32(i * 4, col);
					}
				}
				if( colorDepth == BPP8 ) {
					for (i in 0...bytes.length) {
						var index = r.readByte();
						var color = palette[index];
						converted.setInt32(i * 4, color);
					}
				}
			} else {
				converted = haxe.io.Bytes.alloc(0);
			}

			var dat = new hxd.BitmapData(width, height);
			var pixls = new hxd.Pixels(width, height, converted, hxd.PixelFormat.ARGB);

			dat.setPixels(pixls);
			packer.add(new BitmapDataRect(frameIndex, width, height, dat, xPos, yPos, frame));

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
		packer.nodes.sort((a, b) -> a.index - b.index);
		bmpD.lock();
		for (cel in packer.nodes) {
			var dat = cel.bitmap;

			#if (hl && false)
			bmpD.draw(cel.x, cel.y, dat, 0, 0, cel.width, cel.height, None,);
			#else
			for (dy in 0...cel.height) {
				for (dx in 0...cel.width) {
					bmpD.setPixel(dx + cel.x, dy + cel.y, dat.getPixel(dx, dy));
				}
			}
			#end
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
		bmpD.unlock();

		var png = bmpD.toPNG();

		var fileOutName = '$srcDir/generated/$imageName.png';
		var dir = haxe.io.Path.directory(fileOutName);
		sys.FileSystem.createDirectory(dir);

		sys.io.File.saveBytes(fileOutName, png);
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
			var sliceChunk : ase.chunks.SliceChunk = cast chunk;
			var slice : AsepriteData.AseDataSlice = {
				name : sliceChunk.name,
				keys : [],
			}

			for (key in sliceChunk.sliceKeys) {
				slice.keys.push({
					frame : key.frameNumber,
					x : key.xOrigin,
					y : key.yOrigin,
					w : key.width,
					h : key.height,
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
			var tagsChunk : ase.chunks.TagsChunk = cast chunk;

			for (tag in tagsChunk.tags) {
				var direction : elk.aseprite.AsepriteData.AnimationDirection = switch (tag.animDirection) {
					case 0: Forward;
					case 1: Reverse;
					case 2: PingPong;
					case 3: PingPongReverse;
					default:
						Forward;
				}

				var name = tag.tagName;
				var repeat = !StringTools.startsWith(name, '_');
				if( !repeat ) {
					name = name.substr(1);
				}

				tags.push({
					name : name,
					duration : 0,
					constantSpeed : true,
					from : tag.fromFrame,
					to : tag.toFrame,
					direction : direction,
					repeat : repeat,
				});
			}
		}

		return tags;
	}

	private static inline function getAsePalette(file : ase.Ase) {
		inline function genColor(r, g, b, a) {
			var color : UInt = (b << 24) | (g << 16) | (r << 8) | a;
			return color;
		}

		var colors : Array<UInt> = [];
		var tags : Array<elk.aseprite.AsepriteData.AseDataTag> = [];
		for (frame in file.frames) for (chunk in frame.chunks) {
			if( chunk.header.type == ase.types.ChunkType.OLD_PALETTE_04 ) {
				var paletteChunk : OldPaleteChunk = cast chunk;
				for (p in paletteChunk.packets) {
					var index = p.skipEntries;
					for (c in p.colors) {
						if( index == file.header.paletteEntry ) {
							colors[index] = genColor(0, 0, 0, 0);
						} else {
							colors[index] = genColor(c.red, c.green, c.blue, 0xff);
						}
						index++;
					}
				}
				continue;
			}

			if( chunk.header.type != ase.types.ChunkType.PALETTE ) continue;

			var paletteChunk : ase.chunks.PaletteChunk = cast chunk;
			var index = paletteChunk.firstColorIndex;
			for (index in paletteChunk.entries.keys()) {
				var e = paletteChunk.entries[index];
				var color = genColor(e.red, e.green, e.blue, e.alpha);
				colors[index] = color;
			}
		}

		return colors;
	}

	public static function main() {
		var args = Sys.args();
		export(args[0], args[1]);
	}
}
