package elk;

enum ProcessMode {
	Pausable;
	WhenPaused;
	Always;
	Disabled;
}

class Process {
	static var PROCESSES : Array<Process> = [];

	public var mode : ProcessMode = Pausable;

	public var ignoreTimeScale = false;

	var _paused = false;

	public var priority = 0;

	public function preUpdate() {}

	public function update(dt : Float) {}

	public function postUpdate() {}

	public function tick(dt : Float) {}

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
		hxd.Timer.useManualFrameCount = true;
		PROCESSES.push(this);
	}

	public function togglePause() {
		if( _paused ) resume();
		else pause();
	}

	public static var tickRate(default, set) = 60;
	public static var currentTick = 0;

	static var accumulatedTime = 0.;
	static var frameTime = 1.0 / 60.0;
	static var maxAccumulatedTime = 2.;

	public static var timeScale = 1.0;
	public static var currentTickElapsed = 0.;

	private static function _runUpdate(dt : Float) {
		var scaledDt = dt * timeScale;
		accumulatedTime += scaledDt;
		currentTickElapsed = hxd.Math.clamp(accumulatedTime / frameTime);

		var paused = elk.Elk.instance.paused;

		for (p in PROCESSES) {
			if( p.canRun(paused) ) {
				p.preUpdate();
			}
		}

		currentTickElapsed = hxd.Math.clamp(accumulatedTime / frameTime);

		while (accumulatedTime >= frameTime) {
			currentTick++;
			hxd.Timer.frameCount = currentTick;
			accumulatedTime -= frameTime;
			for (p in PROCESSES) {
				if( p.canRun(paused) ) {
					p.tick(frameTime);
				}
			}
		}

		for (p in PROCESSES) {
			if( p.canRun(paused) ) {
				if( p.ignoreTimeScale ) p.update(dt);
				else p.update(scaledDt);
			}
		}

		currentTickElapsed = hxd.Math.clamp(accumulatedTime / frameTime);
	}

	public function destroy() {
		PROCESSES.remove(this);
	}

	static function set_tickRate(rate : Int) {
		rate = hxd.Math.iclamp(rate, 1, 999);
		frameTime = 1 / rate;
		return tickRate = rate;
	}

	inline private function canRun(rootPaused : Bool) {
		if( _paused ) return false;

		return switch (mode) {
			case Always: true;
			case Disabled: false;
			case Pausable: !rootPaused;
			case WhenPaused: rootPaused;
		}
	}
}
