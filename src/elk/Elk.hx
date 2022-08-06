package elk;

import elk.buildutil.AseConvert;

import elk.gamestate.GameStateHandler;
import elk.entity.EntityManager;
import elk.sound.SoundHandler;

import h3d.Engine;

class Elk extends hxd.App {
	public static var instance: Elk = null;
	
	public var pixelSize = 2;

	public var time = 0.; 
	public var tickRate(default, set) = 60;
	public var currentTickElapsed = 0.;
	public var timeScale = 1.0;

	var frameTime = 0.;

	var accumulatedTime = 0.;
	var maxAccumulatedTime = 2.;

	public var entities: EntityManager;
	public var states: GameStateHandler;
	public var sounds: SoundHandler;

	public function new(tickRate = 60) {
		super();
		instance = this;

		this.tickRate = tickRate;

		hxd.Timer.reset();
		
		initResources();

		states = new GameStateHandler();
		entities = new EntityManager();
		sounds = new SoundHandler();
	}
	
	static function initResources() {
		#if usepak
		hxd.Res.initPak("data");
		#elseif (debug && hl)
		hxd.Res.initLocal();
		hxd.res.Resource.LIVE_UPDATE = true;
		#else
		hxd.Res.initEmbed();
		#end
	}
	
	
	public override function update(dt: Float) {
		super.update(dt);

		var scaledDt = dt * timeScale;
		
		time += scaledDt;
		accumulatedTime += scaledDt;

		currentTickElapsed = hxd.Math.clamp(accumulatedTime / frameTime);

		while (accumulatedTime >= frameTime) {
			accumulatedTime -= frameTime;
			entities.tick(frameTime);
			states.tick(frameTime);
		}

		currentTickElapsed = hxd.Math.clamp(accumulatedTime / frameTime);

		states.update(dt);
	}

	override function render(e:Engine) {
		super.render(e);
		entities.render();
	}
	
	function set_tickRate(rate: Int) {
		rate = hxd.Math.iclamp(rate, 1, 999);
		frameTime = 1 / rate;
		return tickRate = rate;
	}
}