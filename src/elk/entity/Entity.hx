package elk.entity;

class Entity {
	public var x: Float = 0.;
	var _prevX = 0.;
	public var y: Float = 0.;
	var _prevY = 0.;
	public var interpX(get, null): Float;
	public var interpY(get, null): Float;
	
	public var ax = 0.;
	public var ay = 0.;
	public var vx = 0.;
	public var vy = 0.;
	
	public var friction(default, set) = 1.01;
	var frictionDirty = true;
	var _fixedFriction = 1.0;

	public function tick(dt: Float) {
		var fric = 1 / (1 + (dt * friction));

		vx += ax * dt;
		vy += ay * dt;
		x += vx * dt;
		y += vy * dt;

		vx *= fric;
		vy *= fric;
		ax *= fric;
		ay *= fric;
	}

	public function render() {
		
	}

	public inline function preTick() {
		_prevX = x;
		_prevY = y;
	}
	
	inline function get_interpX() {
		var g = elk.Elk.instance.currentTickElapsed;
		return hxd.Math.lerp(_prevX, x, g);
	}

	inline function get_interpY() {
		var g = elk.Elk.instance.currentTickElapsed;
		return hxd.Math.lerp(_prevY, y, g);
	}

	inline function set_friction(friction) {
		frictionDirty = true;
		return this.friction = friction;
	}
}