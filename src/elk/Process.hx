package elk;

class Process {
	static var PROCESSES:Array<Process> = [];
	
	var _paused = false;

	public var priority = 0;

	public function preUpdate() {}

	public function update(dt:Float) {}

	public function postUpdate() {}

	public function tick(dt:Float) {}

	public function pause() {
		_paused = true;
	}

	public function resume() {
		_paused = false;
	}
	
	public function new() {
		init();
	}
	
	function init() {
		PROCESSES.push(this);
	}

	public function togglePause() {
		if (_paused)
			resume();
		else
			pause();
	}
	
	public static var tickRate(default, set) = 60;
	static var accumulatedTime = 0.;
	static var frameTime = 1 / 60;
	static var maxAccumulatedTime = 2.;
	
	public static var timeScale = 1.0;
	public static var currentTickElapsed = 0.;

	public static function _runUpdate(dt:Float) {
		var scaledDt = dt * timeScale;
		accumulatedTime += scaledDt;
		currentTickElapsed = hxd.Math.clamp(accumulatedTime / frameTime);
		
		for (p in PROCESSES) {
			if (!p._paused) {
				p.preUpdate();
			}
		}

		currentTickElapsed = hxd.Math.clamp(accumulatedTime / frameTime);

		while (accumulatedTime >= frameTime) {
			accumulatedTime -= frameTime;
			for (p in PROCESSES) {
				if (!p._paused) {
					p.tick(frameTime);
				}
			}
		}
		
		for (p in PROCESSES) {
			if (!p._paused) {
				p.update(scaledDt);
			}
		}

		currentTickElapsed = hxd.Math.clamp(accumulatedTime / frameTime);
	}
	
	public function destroy() {
		PROCESSES.remove(this);
	}

	static function set_tickRate(rate: Int) {
		rate = hxd.Math.iclamp(rate, 1, 999);
		frameTime = 1 / rate;
		return tickRate = rate;
	}
}
