package elk.aseprite;

import elk.util.BlendModes;
import h3d.Vector4;
import hxd.Pixels;
import ase.chunks.OldPaleteChunk;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import elk.aseprite.AnimationData.AnimationFrame;

private class BitmapDataRect implements elk.util.RectPacker.RectPackNode {
	public var index : Int;
	public var x : Int;
	public var y : Int;

	public var width : Int;
	public var height : Int;
	public var bitmap : Pixels;

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

	public static function export(srcPath : String, destPath : String, isRetry = false) {
		var srcDir = haxe.io.Path.directory(srcPath);
		var imageName = haxe.io.Path.withoutExtension(haxe.io.Path.withoutDirectory(srcPath));

		var fileBytes = sys.io.File.getBytes(srcPath);

		var file : ase.Ase = null;
		try {
			file = ase.Ase.fromBytes(fileBytes);
		} catch (e) {
			if( e is haxe.ValueException && !isRetry ) {
				var r = cast(e, haxe.ValueException);
				if( r.value is haxe.io.Eof ) {
					Sys.sleep(0.2);
					return export(srcPath, destPath, isRetry);
				}
			}
			throw e;
		}

		var tags = getAseTags(file);
		var slices = getAseSlices(file);
		var palette = getAsePalette(file);

		var colorDepth = file.colorDepth;

		var packer = new elk.util.RectPacker<BitmapDataRect>(32, 32);

		var layers = file.layers;

		var groups = new Map<Int, Array<ase.Layer>>();
		var groupStack = [];
		var curDepth = 0;
		var curGroup = null;
		for (i in 0...layers.length) {
			var l = layers[i];
			while (l.chunk.childLevel < groupStack.length) groupStack.pop();
			if( l.chunk.layerType == Group ) {
				var curTop = groupStack.length > 0 ? groupStack[l.chunk.childLevel] : null;
				if( curTop == null || curTop.chunk.childLevel < l.chunk.childLevel ) groupStack.push(l);
				else groupStack[l.chunk.childLevel] = l;
			}

			groups[i] = groupStack.slice(0);
		}

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

			var top = file.height;
			var left = file.width;
			var bottom = 0;
			var right = 0;
			for (i in 0...layers.length) {
				var l = layers[i];
				if( l.chunk.layerType != Normal ) continue;
				if( !l.visible ) continue;
				if( l.chunk.childLevel > 0 ) {
					var visible = true;
					for (group in groups[i]) {
						if( !group.visible ) {
							visible = false;
							break;
						}
					}
					if( !visible ) {
						l.visible = false;
						continue;
					}
				}
				var c = frame.cel(i);
				if( c == null ) continue;
				if( top > c.yPosition ) top = c.yPosition;
				if( left > c.xPosition ) left = c.xPosition;
				if( right < c.xPosition + c.width ) right = c.xPosition + c.width;
				if( bottom < c.yPosition + c.height ) bottom = c.yPosition + c.height;
			}

			var frameWidth = right - left;
			var frameHeight = bottom - top;
			var pixels : Pixels;
			var src = new Vector4();
			var dst = new Vector4();
			var resColor = new Vector4();
			if( frameWidth <= 0 || frameHeight <= 0 ) {
				frameWidth = 0;
				frameHeight = 0;
				var bytes = haxe.io.Bytes.alloc(0);
				pixels = new hxd.Pixels(frameWidth, frameHeight, bytes, hxd.PixelFormat.ARGB);
			} else {
				var bytes = haxe.io.Bytes.alloc(frameWidth * frameHeight * 4);
				pixels = new hxd.Pixels(frameWidth, frameHeight, bytes, hxd.PixelFormat.ARGB);
				var yPos = 0;
				var xPos = 0;

				for (i in 0...layers.length) {
					var l = layers[i];
					if( !l.visible ) continue;

					var cel = frame.cel(i);
					if( cel == null ) continue;

					var width = cel.width;
					var height = cel.height;

					xPos = cel.xPosition - left;
					yPos = cel.yPosition - top;

					var opacity = l.chunk.opacity / 255;

					inline function drawPixel(index : Int, color) {
						var py = Std.int(index / width);
						var px = index % width;
						px += xPos;
						py += yPos;

						pixels.getPixelF(px, py, dst);
						src.setColor(color);
						switch (l.chunk.blendMode) {
							case Normal:
								resColor = BlendModes.normal(src, dst, opacity, resColor);
							case Darken:
								resColor = BlendModes.darken(src, dst, opacity, resColor);
							case Multiply:
								resColor = BlendModes.multiply(src, dst, opacity, resColor);
							case ColorBurn:
								resColor = BlendModes.burn(src, dst, opacity, resColor);
							case Lighten:
								resColor = BlendModes.lighten(src, dst, opacity, resColor);
							case Screen:
								resColor = BlendModes.screen(src, dst, opacity, resColor);
							case ColorDodge:
								resColor = BlendModes.dodge(src, dst, opacity, resColor);
							case Addition:
								resColor = BlendModes.addition(src, dst, opacity, resColor);
							case Overlay:
								resColor = BlendModes.overlay(src, dst, opacity, resColor);
							case SoftLight:
								resColor = BlendModes.soft_light(src, dst, opacity, resColor);
							case HardLight:
								resColor = BlendModes.hard_light(src, dst, opacity, resColor);
							case Difference:
								resColor = BlendModes.difference(src, dst, opacity, resColor);
							case Exclusion:
								resColor = BlendModes.exclusion(src, dst, opacity, resColor);
							case Subtract:
								resColor = BlendModes.subtract(src, dst, opacity, resColor);
							case Divide:
								resColor = BlendModes.divide(src, dst, opacity, resColor);
							case Hue:
								resColor = BlendModes.hue(src, dst, opacity, resColor);
							case Saturation:
								resColor = BlendModes.saturation(src, dst, opacity, resColor);
							case Color:
								resColor = BlendModes.color(src, dst, opacity, resColor);
							case Luminosity:
								resColor = BlendModes.luminosity(src, dst, opacity, resColor);
						}

						pixels.setPixelF(px, py, resColor);
					}

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

							var pixelColor = (A << 24) | (R << 16) | (G << 8) | B;
							drawPixel(i, pixelColor);
						}
					}
					if( colorDepth == BPP8 ) {
						for (i in 0...bytes.length) {
							var index = r.readByte();
							var color = palette[index];
							drawPixel(i, color);
						}
					}
				}
			}

			packer.add(new BitmapDataRect(frameIndex, frameWidth, frameHeight, pixels, left, top, frame));

			frameIndex++;
		}

		packer.refresh();
		var w = packer.width;
		var h = packer.height;
		var bmpD = new Pixels(packer.width, packer.height, haxe.io.Bytes.alloc(w * h * 4), ARGB);
		var info = new AnimationData();

		for (tag in tags) info.tags[tag.name] = tag;
		for (slice in slices) info.slices[slice.name] = slice;

		info.width = file.width;
		info.height = file.height;

		var frames : Array<AnimationFrame> = [];

		info.frames = frames;
		packer.nodes.sort((a, b) -> a.index - b.index);
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

	private static inline function getAseSlices(file : ase.Ase) : Array<AnimationData.AnimationSlice> {
		var slices = [];
		for (chunk in file.firstFrame.chunks) {
			if( chunk.header.type != ase.types.ChunkType.SLICE ) continue;
			var sliceChunk : ase.chunks.SliceChunk = cast chunk;
			var slice : AnimationData.AnimationSlice = {
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
		var tags : Array<elk.aseprite.AnimationData.AnimationTag> = [];
		for (chunk in file.firstFrame.chunks) {
			if( chunk.header.type != ase.types.ChunkType.TAGS ) continue;
			var tagsChunk : ase.chunks.TagsChunk = cast chunk;

			for (tag in tagsChunk.tags) {
				var direction : elk.aseprite.AnimationData.AnimationDirection = switch (tag.animDirection) {
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
		var tags : Array<elk.aseprite.AnimationData.AnimationTag> = [];
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

		colors = colors.map(col -> {
			var R = (col & 0x000000ff);
			var G = (col & 0x0000ff00) >> 8;
			var B = (col & 0x00ff0000) >> 16;
			var A = cast(col & 0xff000000, UInt) >> 24;

			return (R << 24) | (G << 16) | (B << 8) | A;
		});

		return colors;
	}

	public static function main() {
		var args = Sys.args();
		export(args[0], args[1]);
	}
}
