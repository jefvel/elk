package elk;

import elk.graphics.filter.RetroFilter;
import h2d.Bitmap;
import h3d.mat.DepthBuffer;
import h3d.scene.RenderContext;
import h3d.mat.Texture;
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
	
	public var renderer: elk.graphics.CustomRenderer;

	public function new(tickRate = 60, pixelSize = 2) {
		super();
		instance = this;

		Process.tickRate = tickRate;
		this.pixelSize = pixelSize;

		initResources();
	}
	
	override function init() {
		super.init();

		initRenderer();

		hxd.Timer.reset();
		
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
	
	override function onResize() {
		super.onResize();
		if (s2d == null) {
			return;
		}
		
		var w = Std.int(engine.width / pixelSize);
		var h = Std.int(engine.height / pixelSize);

		this.windowWidth = w;
		this.windowHeight = h;

		s2d.scaleMode = ScaleMode.Stretch(w, h);

		if (buf != null) {
			buf.resize(engine.width, engine.height);
			buf.depthBuffer.dispose();
			s3dBitmap.width = buf.width;
			s3dBitmap.height = buf.height;
		} else {
			buf = new Texture(w, h, [Target]);
			buf.setName("s3dbuffer");
			s3dBitmap = new Bitmap(h2d.Tile.fromTexture(buf), s2d);
		}

		buf.depthBuffer = new DepthBuffer(buf.width, buf.height);
		var scale = s2d.width / buf.width;
		s3dBitmap.setScale(scale);
	}
	
	function initRenderer() {
		// Image filtering set to nearest sharp pixel graphics.
		// If you don't want crisp pixel graphics you can just
		// remove this
		hxd.res.Image.DEFAULT_FILTER = Nearest;
		
		var bgColorString = haxe.macro.Compiler.getDefine("backgroundColor");
		if (bgColorString != null) {
			bgColorString = StringTools.replace(bgColorString, "#", "0x");
			var color = Std.parseInt(bgColorString);
			engine.backgroundColor = 0xff000000 | color;
		}
		
		renderer = new elk.graphics.CustomRenderer();
		s3d.renderer = renderer;
		renderer.uiScene = s2d;

		#if js
		// This causes the game to not be super small on high DPI mobile screens
		hxd.Window.getInstance().useScreenPixels = false;
		#end

		s2d.filter = new RetroFilter();

		onResize();
	}
	
	var buf: h3d.mat.Texture;
	var ctx: RenderContext;

	public var s3dBitmap: Bitmap;
	
	public override function update(dt: Float) {
		super.update(dt);
		Process._runUpdate(dt);
	}

	override function render(e:Engine) {
		e.pushTarget(buf);
		e.clear(e.backgroundColor, 1);
		s3d.render(e);
		e.popTarget();
		
		//h3d.pass.Copy.run(buf, null);
		//e.pushTarget(buf);
		//buf.depthBuffer = DepthBuffer.getDefault();
		//buf.clear(e.backgroundColor, 1);
		s2d.render(e);

		entities.render();
		drawCalls = e.drawCalls;

		//e.popTarget();
		//pass.apply(ctx, buf);
		//h3d.pass.Copy.run(buf, null, Add);
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