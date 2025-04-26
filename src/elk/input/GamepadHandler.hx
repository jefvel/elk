package elk.input;

#if !disableGamepads
import hxd.Pad;

class GamepadHandler extends Process {
	override function init() {
		super.init();
		#if enableGamepads
		awaitGamepad();
		#end
	}

	public var inFocus = true;

	public var pad : Pad = null;
	public var connected = false;

	function awaitGamepad() {
		Pad.wait(onGamepadConnect);
	}

	public function anyButtonPressed() {
		if( !isActive() ) {
			return false;
		}
		for (v in pad.values) {
			if( Math.abs(v) > 0.4 ) {
				return true;
			}
		}
		return false;
	}

	public function vibrate(duration : Int, strength = 1.0) {
		if( !isActive() ) {
			return false;
		}

		pad.rumble(strength, duration / 1000.);

		return true;
	}

	function onGamepadConnect(pad : hxd.Pad) {
		trace("Gamepad connected");
		if( this.pad != null ) {
			return;
		}

		this.connected = true;

		this.pad = pad;
		pad.axisDeadZone = 0.2;

		pad.onDisconnect = () -> {
			trace("disconnected");
			this.pad = null;
			this.connected = false;
		}

		awaitGamepad();
	}

	public var prevValues : Array<Float> = [];

	var prevButtons : Array<Bool> = [];

	override function tick(dt : Float) {
		super.tick(dt);
		var p = pad;

		if( pad == null ) return;

		var buttons = @:privateAccess p.buttons;
		var values = p.values;

		for (i in 0...buttons.length) prevButtons[i] = buttons[i];
		for (i in 0...values.length) prevValues[i] = values[i];
	}

	final conf = hxd.Pad.DEFAULT_CONFIG;

	public function isBtnDown(btn) {
		if( !isActive() ) {
			return false;
		}

		return pad.isDown(btn);
	}

	public function isBtnPressed(btn) {
		if( !isActive() ) {
			return false;
		}

		return pad.isDown(btn) && !prevButtons[btn];
	}

	public function getStickX() : Float {
		if( !isActive() ) {
			return 0;
		}

		return pad.xAxis;
	}

	public function getStickY() : Float {
		if( !isActive() ) {
			return 0;
		}

		return pad.yAxis;
	}

	inline function isActive() {
		return pad != null && inFocus;
	}

	final dz = 0.5;

	public function pressingLeft() {
		return isActive() && pad.xAxis < -dz;
	}

	public function pressingRight() {
		return isActive() && pad.xAxis > dz;
	}

	public function pressingUp() {
		return isActive() && pad.yAxis < -dz;
	}

	public function pressingDown() {
		return isActive() && pad.yAxis > dz;
	}
}
#end
