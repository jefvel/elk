package elk.graphics;

import h2d.Tile;
import elk.aseprite.AsepriteData;

class Animation {
	var data: AsepriteData = null;
	
	var currentAnimation: AseDataTag = null;
	public var currentFrame : AseDataFrame = null;
	
	public var timeScale = 1.0;
	
	var currentFrameIndex = 0;
	var from = 0;
	var to = 0;
	var finished = false;
	
	public var pause = false;
	public var loop = true;
	
	var elapsedTime = 0.;
	var elapsedFrameTime = 0.;

	public var tile(get, null): Tile;
	
	public var onEnterFrame: Int -> Void = null;
	
	public dynamic function onEnd(anim: AseDataTag) {}

	public function new(data: AsepriteData) {
		this.data = data;
		to = data.frames.length - 1;
		currentFrame = data.frames[0];
	}
	
	public function play(animationName: String = null, loop = true, force = false, percentage = 0.) {
		if (currentAnimation != null) {
			if(animationName == currentAnimation.name && !force) {
				return false;
			}
		}

		currentAnimation = data.tags.get(animationName);

		elapsedTime = elapsedFrameTime = 0;
		this.loop = loop;
		finished = false;
		
		if (currentAnimation != null) {
			from = currentAnimation.from;
			to = currentAnimation.to;
			currentFrameIndex = from;
		}

		percentage = hxd.Math.clamp(percentage);

		if (percentage > 0) {
			if (currentAnimation == null) {
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
	
	public function update(dt: Float) {
		if (pause || finished) return;

		dt *= timeScale;
		
		var frame = data.frames[currentFrameIndex];

		elapsedFrameTime += dt;
		elapsedTime += dt;
		
		while (elapsedFrameTime * 1000 >= frame.duration) {
			elapsedFrameTime -= frame.duration / 1000;
			currentFrameIndex ++;
			
			if (loop) {
				if (currentFrameIndex > to) {
					currentFrameIndex = from;
				}
				if (onEnterFrame != null) {
					onEnterFrame(currentFrameIndex);
				}
			} else {
				if (currentFrameIndex > to) {
					currentFrameIndex = to;
					if (!finished) {
						finished = true;
						if (onEnterFrame != null) {
							onEnterFrame(currentFrameIndex);
						}
						onEnd(currentAnimation);
					}
				}
			}
			
			currentFrame = data.frames[currentFrameIndex];
		}
	}
	
	public function getSlice(name: String) {
		var f = currentFrame;
		if (f.slices == null) {
			return null;
		}
		
		return f.slices.get(name);
	}
	
	function get_tile() {
		return currentFrame.tile;
	}
}