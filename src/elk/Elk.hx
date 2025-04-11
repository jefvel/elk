package elk;

import elk.input.Input;
import hxd.res.DefaultFont;
import hxd.fs.MultiFileSystem;
import hxd.fs.EmbedFileSystem;
import hxd.Window;
import elk.util.ResTools;
import h2d.Bitmap;
import h3d.scene.RenderContext;
import elk.aseprite.AsepriteConvert;
import elk.gamestate.GameStateHandler;
import elk.entity.EntityManager;
import elk.sound.SoundHandler;
import h3d.Engine;

enum AppType {
	App;
	Dedicated;
}

class Elk extends hxd.App {
	public static var instance : Elk = null;

	public static var type : AppType = App;

	public var time : Float = 0.0;
	public var scaledTime : Float = 0.0;

	public var input : Input;

	public var paused = false;

	public var pixelSize(default, set) = 2;

	public var window_scale(default, set) = #if js 1.0 #else 1.0 #end;

	public var tickRate(get, set) : Int;
	public var timeScale(get, set) : Float;

	public var entities : EntityManager;
	public var states : GameStateHandler;
	public var sounds : SoundHandler;

	public var console : h2d.Console;

	/**
	 * automatically sets scalemode
	 */
	public var autoResize = true;

	public var windowWidth = 0;
	public var windowHeight = 0;

	public var drawCalls = 0;

	public var renderer : elk.graphics.CustomRenderer;

	var loaded_assets : Bool = false;

	public var is_ready(get, null) : Bool;

	function get_is_ready()
		return loaded_assets;

	public function new(tickRate = 60, pixelSize = 2) {
		instance = this;
		super();

		Process.tickRate = tickRate;
		this.pixelSize = pixelSize;

		#if sys
		switch (Sys.systemName()) {
			case "Mac", "Linux":
				window_scale = 1.0;
		}
		#end
	}

	function set_window_scale(s : Float) {
		window_scale = s;
		onResize();
		return window_scale;
	}

	public function on_ready() {
		loaded_assets = true;

		// hxd.Timer.useManualFrameCount = true;
		onResize();

		#if hl
		var win = Window.getInstance();
		win.resize(Std.int(win.width * window_scale), Std.int(win.height * window_scale));
		#end
	}

	override function init() {
		super.init();

		states = new GameStateHandler(this);
		entities = new EntityManager();
		sounds = new SoundHandler();

		input = Input.instance;

		initResources();
		elk.castle.CastleDB.init();

		initRenderer();

		console = new h2d.Console(DefaultFont.get(), s2d);
		console.shortKeyChar = '§'.charCodeAt(0);
	}

	public function on_load_progress(progress : Float) {}

	function initResources() {
		var mark_ready = () -> haxe.Timer.delay(on_ready, 0);

		#if (use_pak)
		ResTools.initPakAuto( //
			null, //
			mark_ready, //
			on_load_progress, //
			'web', //
		);
		return;
		#elseif (debug && hl)
		hxd.Res.initLocal();
		#if live_reload
		hxd.res.Resource.LIVE_UPDATE = true;
		#end
		#else
		hxd.Res.initEmbed();
		#end

		/*
			#if macro
			var pre = EmbedFileSystem.create(null);
			hxd.Res.loader = macro new hxd.res.Loader(new MultiFileSystem([hxd.Res.loader.fs, pre]));
			#end
		 */

		mark_ready();
	}

	override function onResize() {
		super.onResize();

		var w = Std.int(engine.width / pixelSize / window_scale);
		var h = Std.int(engine.height / pixelSize / window_scale);

		if( s2d == null ) {
			return;
		}

		s2d.scaleMode = ScaleMode.Stretch(w, h);

		this.windowWidth = w;
		this.windowHeight = h;

		/*
			if (buf != null) {
				buf.resize(w, h);
				buf.depthBuffer.dispose();
				s3dBitmap.width = buf.width;
				s3dBitmap.height = buf.height;
			} else {
				buf = new Texture(w, h, [Target]);
				buf.setName("s3dbuffer");
				s3dBitmap = new Bitmap(h2d.Tile.fromTexture(buf), s2d);
			}

			buf.depthBuffer = new Texture(buf.width, buf.height);
			var scale = s2d.width / buf.width;
			s3dBitmap.setScale(scale);
		 */
	}

	function initRenderer() {
		// Image filtering set to nearest sharp pixel graphics.
		// If you don't want crisp pixel graphics you can just
		// remove this
		hxd.res.Image.DEFAULT_FILTER = Nearest;

		var bgColorString = haxe.macro.Compiler.getDefine("backgroundColor");
		if( bgColorString != null ) {
			bgColorString = StringTools.replace(bgColorString, "#", "0x");
			var color = Std.parseInt(bgColorString);
			engine.backgroundColor = 0xff000000 | color;
		}

		// renderer = new elk.graphics.CustomRenderer();
		// s3d.renderer = renderer;

		#if js
		// This causes the game to not be super small on high DPI mobile screens
		hxd.Window.getInstance().useScreenPixels = false;
		#end

		onResize();
	}

	var buf : h3d.mat.Texture;
	var ctx : RenderContext;

	public var s3dBitmap : Bitmap;

	public override function update(dt : Float) {
		super.update(dt);
		if( console?.isActive() ) {
			s2d.addChild(console);
			Input.disableInput = true;
		} else {
			Input.disableInput = false;
		}
		time += dt;
		scaledTime += dt * timeScale;
		@:privateAccess Process._runUpdate(dt);

		#if hot_reload
		hl.Api.checkReload();
		#end

		#if sys
		if( Sys.systemName() == "Mac" && hxd.Key.isDown(hxd.Key.LEFT_WINDOW_KEY) ) {
			if( hxd.Key.isPressed(hxd.Key.Q) ) {
				hxd.System.exit();
			}
		}
		#end
	}

	override function render(e : Engine) {
		@:privateAccess s3d.ctx.elapsedTime *= timeScale;

		e.pushTarget(buf);
		e.clear(e.backgroundColor, 1);
		s3d.render(e);
		e.popTarget();

		s2d.render(e);

		if( entities != null ) entities.render();
		drawCalls = e.drawCalls;
	}

	function set_pixelSize(size : Int) {
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
