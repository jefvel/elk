package elk.aseprite;

import haxe.io.BytesInput;

enum abstract AnimationDirection(Int) {
	var Forward = 0;
	var Reverse = 1;
	var PingPong = 2;
	var PingPongReverse = 3;
}

@:structInit
class AnimationFrame {
	public var x : Int;
	public var y : Int;
	public var w : Int;
	public var h : Int;

	public var dx : Int;
	public var dy : Int;

	public var duration : Int;

	public var tile : h2d.Tile = null;
	public var slices : Map<String, AnimationSliceKey> = null;

	public inline function serialize(o : haxe.io.Output) {
		o.writeInt32(x);
		o.writeInt32(y);
		o.writeInt32(w);
		o.writeInt32(h);
		o.writeInt32(dx);
		o.writeInt32(dy);
		o.writeInt32(duration);
	}

	public static function deserialize(o : haxe.io.Input) : AnimationFrame {
		return {
			x : o.readInt32(),
			y : o.readInt32(),
			w : o.readInt32(),
			h : o.readInt32(),
			dx : o.readInt32(),
			dy : o.readInt32(),
			duration : o.readInt32(),
		}
	}
}

@:structInit
class AnimationTag {
	public var name : String;
	public var duration : Int;
	public var constantSpeed : Bool;
	public var from : Int;
	public var to : Int;
	public var direction : AnimationDirection = Forward;
	public var repeat : Bool;

	public function toString() {
		return '$name [$from - $to], duration: $duration, constant: $constantSpeed, direction: $direction, repeat: $repeat';
	}

	public function copyFrom(t : AnimationTag) {
		name = t.name;
		duration = t.duration;
		constantSpeed = t.constantSpeed;
		from = t.from;
		to = t.to;
		direction = t.direction;
		repeat = t.repeat;
	}

	public inline function serialize(w : haxe.io.Output) {
		w.writeInt32(name.length);
		w.writeString(name);
		w.writeInt32(duration);
		w.writeByte(constantSpeed ? 1 : 0);
		w.writeInt32(from);
		w.writeInt32(to);
		w.writeByte(cast direction);
		w.writeByte(repeat ? 1 : 0);
	}

	public static function deserialize(w : haxe.io.Input) : AnimationTag {
		var nameLength = w.readInt32();
		return {
			name : w.readString(nameLength),
			duration : w.readInt32(),
			constantSpeed : w.readByte() == 1,
			from : w.readInt32(),
			to : w.readInt32(),
			direction : cast w.readByte(),
			repeat : w.readByte() == 1,
		}
	}
}

@:structInit
class AnimationSlice {
	public var name : String;
	public var keys : Array<AnimationSliceKey>;

	public function toString() {
		return '$name: [\n${keys.map(k -> '  frame: ${k.frame}, x:${k.x}, y: ${k.y} (${k.w}x${k.h})').join('\n')}\n]';
	}

	public function copyFrom(s : AnimationSlice) {
		name = s.name;
		for (i in 0...s.keys.length) {
			if( keys[i] != null ) {
				keys[i].copyFrom(s.keys[i]);
			} else {
				keys.push(s.keys[i]);
			}
		}
		if( s.keys.length > keys.length ) {
			keys.splice(s.keys.length - 1, -1);
		}
	}

	public inline function serialize(w : haxe.io.Output) {
		w.writeInt32(name.length);
		w.writeString(name);
		w.writeInt32(keys.length);
		for (k in keys) k.serialize(w);
	}

	public static function deserialize(w : haxe.io.Input) : AnimationSlice {
		var nameLength = w.readInt32();
		var name = w.readString(nameLength);
		var keyCount = w.readInt32();
		var keys = [];
		for (ki in 0...keyCount) keys.push(AnimationSliceKey.deserialize(w));
		return {
			name : name,
			keys : keys,
		}
	}
}

@:structInit
class AnimationSliceKey {
	public var frame : Int;
	public var x : Int;
	public var y : Int;
	public var w : Int;
	public var h : Int;

	public inline function serialize(o : haxe.io.Output) {
		o.writeInt32(frame);
		o.writeInt32(x);
		o.writeInt32(y);
		o.writeInt32(w);
		o.writeInt32(h);
	}

	public function copyFrom(k : AnimationSliceKey) {
		frame = k.frame;
		x = k.x;
		y = k.y;
		w = k.w;
		h = k.h;
	}

	public static function deserialize(o : haxe.io.Input) : AnimationSliceKey {
		return {
			frame : o.readInt32(),
			x : o.readInt32(),
			y : o.readInt32(),
			w : o.readInt32(),
			h : o.readInt32(),
		}
	}
}

@:structInit
class AnimationData {
	public var width : Int = 0;
	public var height : Int = 0;

	public var frames : Array<AnimationFrame> = [];
	public var tags : Map<String, AnimationTag> = new Map();
	public var slices : Map<String, AnimationSlice> = new Map();

	public var totalDuration : Int = 0;

	public var rootTile : h2d.Tile;

	public function new() {}

	public function copyFrom(data : AnimationData) {
		width = data.width;
		height = data.height;

		totalDuration = data.totalDuration;
		rootTile = data.rootTile;

		for (i in 0...data.frames.length) {
			var oldFrame = frames[i];
			var newFrame = data.frames[i];
			if( oldFrame == null ) {
				frames.push(newFrame);
			} else {
				oldFrame.x = newFrame.x;
				oldFrame.y = newFrame.y;
				oldFrame.duration = newFrame.duration;
				oldFrame.dx = newFrame.dx;
				oldFrame.dy = newFrame.dy;
				oldFrame.slices = newFrame.slices;
				oldFrame.tile = newFrame.tile;
				oldFrame.w = newFrame.w;
				oldFrame.h = newFrame.h;
			}
		}

		if( data.frames.length < frames.length ) {
			frames.splice(data.frames.length, -1);
		}

		for (k => v in data.tags.keyValueIterator()) {
			if( tags.exists(k) ) {
				tags[k].copyFrom(v);
			} else {
				tags.set(k, v);
			}
		}

		for (k => v in data.slices.keyValueIterator()) {
			if( slices.exists(k) ) {
				slices[k].copyFrom(v);
			} else {
				slices.set(k, v);
			}
		}
	}

	private static inline function dynToMap(objo) : Map<String, Dynamic> {
		var res = new Map();
		var obj : haxe.DynamicAccess<Dynamic> = objo;
		for (key in obj.keys()) {
			res.set(key, obj.get(key).value);
		}
		return res;
	}

	public static function load(r : haxe.io.Input) : AnimationData {
		var d = new AnimationData();
		// var r = new BytesInput(entry.getBytes());

		d.width = r.readInt32();
		d.height = r.readInt32();
		d.totalDuration = r.readInt32();

		var frameCount = r.readInt32();
		for (fi in 0...frameCount) d.frames.push(AnimationFrame.deserialize(r));

		var tagsCount = r.readInt32();
		for (tc in 0...tagsCount) {
			var tag = AnimationTag.deserialize(r);
			d.tags.set(tag.name, tag);
		}

		var sliceCount = r.readInt32();
		for (sc in 0...sliceCount) {
			var slice = AnimationSlice.deserialize(r);
			d.slices.set(slice.name, slice);
		}

		r.close();

		return d;
	}

	public function writeToFile(w : haxe.io.Output) {
		w.writeInt32(width);
		w.writeInt32(height);
		w.writeInt32(totalDuration);

		w.writeInt32(frames.length);
		for (f in frames) f.serialize(w);

		// Tags
		var tagsArray = [];
		for (name in tags.keys()) tagsArray.push(tags[name]);
		w.writeInt32(tagsArray.length);
		for (tag in tagsArray) tag.serialize(w);

		// Slcies
		var slicesArray = [];
		for (name in slices.keys()) slicesArray.push(slices[name]);
		w.writeInt32(slicesArray.length);
		for (s in slicesArray) s.serialize(w);

		// w.flush();
		// hxd.File.saveBytes(destPath, w.getBytes());
		// w.close();
	}
}
