package elk.util;

private class IFImpl {
	private var previousTick = 0;
	private var previous = 0.0;
	private var current = 0.0;

	public var value(get, set) : Float;

	public function new(value : Float = 0.0) {
		previous = current = value;
		previousTick = Process.currentTick;
	}

	function set_value(v) {
		var currentTick = Process.currentTick;
		if( previousTick != currentTick ) {
			previous = current;
			previousTick = currentTick;
		}
		return current = v;
	}

	function get_value() {
		var g = Process.currentTickElapsed;
		return hxd.Math.lerp(previous, current, g);
	}
}

@:forward abstract InterpolatedFloat(IFImpl) from IFImpl to IFImpl {
	public inline function new(value = 0.0) {
		this = new IFImpl(value);
	}

	@:op(A + B)
	public inline function add(rhs : Float)
		return this.value + rhs;

	@:op(A - B)
	public inline function sub(rhs : Float)
		return this.value - rhs;

	@:op(A += B)
	public inline function addRet(rhs : Float)
		return this.value += rhs;

	@:op(A -= B)
	public inline function subRet(rhs : Float)
		return this.value -= rhs;

	@:op(A * B)
	public inline function mul(rhs : Float)
		return this.value * rhs;

	@:op(A *= B)
	public inline function mulRet(rhs : Float)
		return this.value *= rhs;

	@:op(A / B)
	public inline function div(rhs : Float)
		return this.value / rhs;

	@:op(A /= B)
	public inline function divRet(rhs : Float)
		return this.value /= rhs;
}
