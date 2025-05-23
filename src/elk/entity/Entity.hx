package elk.entity;

@:keepSub
class Entity {
	// public var x: Float = 0.;
	var _prevX = 0.;
	// public var y: Float = 0.;
	var _prevY = 0.;

	public var z : Float = 0.;

	var _prevZ = 0.;

	public var x = 0.0;
	public var y = 0.0;

	public var interpX(get, null) : Float;
	public var interpY(get, null) : Float;
	public var interpZ(get, null) : Float;

	public var ax = 0.;
	public var ay = 0.;
	public var az = 0.;

	public var vx = 0.;
	public var vy = 0.;
	public var vz = 0.;

	public var owner(default, set) : h2d.Object = null;

	function set_owner(s : h2d.Object) {
		return owner = s;
	}

	public function new() {
		Elk.instance.entities.add(this);
		reset();
	}

	public function remove() {
		if( owner != null ) owner.remove();
		Elk.instance.entities.remove(this);
	}

	function reset() {
		ax = ay = az = vx = vy = vz = x = y = z = 0.0;
	}

	public var friction(default, set) = 1.01;

	var frictionDirty = true;
	var _fixedFriction = 1.0;

	public function tick(dt : Float) {
		var fric = 1 / (1 + (dt * friction));

		vx += ax * dt;
		vy += ay * dt;

		x += vx * dt;
		y += vy * dt;
		z += vz * dt;

		vx *= fric;
		vy *= fric;
		vz *= fric;

		ax *= fric;
		ay *= fric;
		az *= fric;
	}

	public function render(dt : Float) {}

	public inline function preTick() {
		_prevX = x;
		_prevY = y;
		_prevZ = z;
	}

	inline function get_interpX() {
		var g = elk.Process.currentTickElapsed;
		return hxd.Math.lerp(_prevX, x, g);
	}

	inline function get_interpY() {
		var g = elk.Process.currentTickElapsed;
		return hxd.Math.lerp(_prevY, y, g);
	}

	inline function get_interpZ() {
		var g = elk.Process.currentTickElapsed;
		return hxd.Math.lerp(_prevZ, z, g);
	}

	inline function set_friction(friction) {
		frictionDirty = true;
		return this.friction = friction;
	}
}
