package elk;

import elk.aseprite.AsepriteConvert;

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
		initRenderer();

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
	
	function initRenderer() {
		// Image filtering set to nearest sharp pixel graphics.
		// If you don't want crisp pixel graphics you can just
		// remove this
		hxd.res.Image.DEFAULT_FILTER = Nearest;

		#if js
		// This causes the game to not be super small on high DPI mobile screens
		hxd.Window.getInstance().useScreenPixels = false;
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