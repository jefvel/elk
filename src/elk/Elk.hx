package elk;

import elk.aseprite.AsepriteConvert;

import elk.gamestate.GameStateHandler;
import elk.entity.EntityManager;
import elk.sound.SoundHandler;

import h3d.Engine;

class Elk extends hxd.App {
	public static var instance: Elk = null;
	
	public var pixelSize(default, set) = 2;

	public var tickRate(get, set): Int;
	public var timeScale(get, set): Float;

	public var entities: EntityManager;
	public var states: GameStateHandler;
	public var sounds: SoundHandler;
	
	public var windowWidth = 0;
	public var windowHeight = 0;
	
	public var drawCalls = 0;

	public function new(tickRate = 60, pixelSize = 2) {
		super();
		instance = this;

		Process.tickRate = tickRate;
		this.pixelSize = pixelSize;

		initRenderer();
		initResources();
	}
	
	override function init() {
		super.init();

		hxd.Timer.reset();
		
		states = new GameStateHandler();
		entities = new EntityManager();
		sounds = new SoundHandler();
		
		onResize();
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
	
	override function onResize() {
		super.onResize();
		if (s2d == null) {
			return;
		}
		
		var s = hxd.Window.getInstance();
		
		var w = Std.int(s.width / pixelSize);
		var h = Std.int(s.height / pixelSize);

		this.windowWidth = w;
		this.windowHeight = h;

		s2d.scaleMode = ScaleMode.Stretch(w, h);
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
		
		Process._runUpdate(dt);

	}

	override function render(e:Engine) {
		super.render(e);
		entities.render();
		drawCalls = e.drawCalls;
	}
	
	function set_pixelSize(size: Int) {
		this.pixelSize = size;
		onResize();

		return pixelSize = size;
	}
	
	function get_timeScale() {
		return Process.timeScale;
	}
	function set_timeScale(s) {
		return Process.timeScale = s;
	}

	function get_tickRate() {
		return Process.tickRate;
	}
	function set_tickRate(s) {
		return Process.tickRate = s;
	}
}