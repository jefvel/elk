package elk.graphics;

import h2d.Tile;
import elk.aseprite.AnimationData;

class Animation {
	var data : AnimationData = null;

	var currentAnimation : AnimationTag = null;

	public var currentFrame : AnimationFrame = null;

	public var timeScale = 1.0;

	public var currentFrameIndex = 0;

	var from = 0;
	var to = 0;
	var finished = false;

	public var pause = false;
	public var loop = true;

	public var frameCount(get, null) : Int;

	function get_frameCount() {
		return data?.frames.length ?? 0;
	}

	var elapsedTime = 0.;
	var elapsedFrameTime = 0.;

	// Current progress of the animation, from 0 to 1
	public var progress(null, set) : Float;

	/**
	 * returns the width of the frame of the animation
	 */
	public var width(get, null) : Int;

	/**
	 * returns the height of the frame of the animation
	 */
	public var height(get, null) : Int;

	/**
	 * returns the current tile of the animation
	 */
	public var tile(get, null) : Tile;

	public var onEnterFrame : Int -> Void = null;

	public dynamic function onEnd(anim : String) {}

	public function new(data : AnimationData) {
		this.data = data;
		to = data.frames.length - 1;
		currentFrame = data.frames[0];
	}

	public function play(animationName : String = null, loop = true, force = false, percentage = 0.) {
		if( currentAnimation != null ) {
			if( animationName == currentAnimation.name && !force ) {
				return false;
			}
		}

		currentAnimation = data.tags.get(animationName);

		elapsedTime = elapsedFrameTime = 0;
		this.loop = loop;
		finished = false;

		if( currentAnimation != null ) {
			from = currentAnimation.from;
			to = currentAnimation.to;
			currentFrameIndex = from;
		}

		percentage = hxd.Math.clamp(percentage);

		if( percentage > 0 ) {
			if( currentAnimation == null ) {
				elapsedFrameTime = data.totalDuration / 1000.0 * percentage;
			} else {
				elapsedFrameTime = currentAnimation.duration / 1000.0 * percentage;
			}
			var f = data.frames[currentFrameIndex];
			while (elapsedFrameTime * 1000 >= f.duration) {
				elapsedFrameTime -= f.duration / 1000.0;
				elapsedTime += f.duration / 1000.0;
				currentFrameIndex++;
				currentFrame = data.frames[currentFrameIndex];
			}
		}

		currentFrame = data.frames[currentFrameIndex];
		return true;
	}

	public function update(dt : Float) {
		var frame = data.frames[currentFrameIndex];
		if( pause && currentFrame != frame ) {
			currentFrame = frame;
			return;
		}

		if( pause || finished ) return;

		dt *= timeScale;

		elapsedFrameTime += dt;
		elapsedTime += dt;

		while (elapsedFrameTime * 1000 >= frame.duration) {
			elapsedFrameTime -= frame.duration / 1000;
			currentFrameIndex++;

			if( loop ) {
				if( currentFrameIndex > currentAnimation?.to ?? to ) {
					currentFrameIndex = currentAnimation?.from ?? from;
				}
				if( onEnterFrame != null ) {
					onEnterFrame(currentFrameIndex);
				}
			} else {
				if( onEnterFrame != null ) {
					onEnterFrame(currentFrameIndex);
				}
				if( currentFrameIndex > to ) {
					currentFrameIndex = to;
					if( !finished ) {
						finished = true;
						if( currentAnimation != null && onEnd != null ) {
							onEnd(currentAnimation.name);
						}
					}
				}
			}

			currentFrame = data.frames[currentFrameIndex];
		}
	}

	public function getSlice(name : String) {
		var f = currentFrame;
		if( f.slices == null ) {
			return null;
		}

		return f.slices.get(name);
	}

	function get_tile() {
		return currentFrame.tile;
	}

	function get_width()
		return data.width;

	function get_height()
		return data.height;

	function set_progress(p : Float) {
		currentFrameIndex = 0;
		elapsedTime = 0.0;
		var total_duration = currentAnimation != null ? (currentAnimation.duration * 0.001) : data.totalDuration;
		elapsedFrameTime = p * total_duration;
		return p;
	}
}
