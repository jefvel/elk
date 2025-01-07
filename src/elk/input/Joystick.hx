package elk.input;

import h2d.RenderContext;
import elk.util.EasedFloat;
import h2d.Object;
import h2d.col.Point;
import h2d.Graphics;

enum JoystickSide {
	Left;
	Right;
}

class Joystick extends Object {
	var bg:Graphics;
	var dot:Graphics;
	var r = 54.;
	var maxR = 92;

	#if js
	public var touchId = null;
	#else
	public var touchId = 0;
	#end
	public var active = false;

	public var mx = 0.;
	public var my = 0.;

	public var magnitude = 0.0;
	public var side = Left;

	public var doubleTapped = false;
	public var doubleTapTime = 0.25;

	var eased_scale = EasedFloat.elastic(0.0, 0.3);

	var tapTime = 0.;

	public var onActivate:Void->Void = null;

	public function new(side:JoystickSide = Left, ?p) {
		super(p);
		this.side = side;
		visible = false;
		bg = new Graphics(this);
		dot = new Graphics(this);
		refreshGraphics();
	}

	public override function onAdd() {
		super.onAdd();
		hxd.Window.getInstance().addEventTarget(handleEvent);
	}

	public override function onRemove() {
		super.onRemove();
		hxd.Window.getInstance().removeEventTarget(handleEvent);
	}

	public function refreshGraphics() {
		bg.clear();
		bg.beginFill(0x111111, 0.4);
		bg.drawCircle(0, 0, r);
		dot.clear();
		dot.beginFill(0x151522, 0.9);
		dot.drawCircle(0, 0, r * 0.3);
	}

	public function handleEvent(e:hxd.Event) {
		#if js
		var s2d = getScene();
		if (s2d == null)
			return false;
		var g = s2d.globalToLocal(new Point(e.relX, e.relY));
		g.x /= elk.Elk.instance.pixelSize;
		g.y /= elk.Elk.instance.pixelSize;

		if (e.kind == EPush) {
			if (g.y < s2d.height * 0.5) {
				return false;
			}

			var valid = g.x < s2d.width * 0.5;
			if (side == Right) {
				valid = g.x > s2d.width * 0.5;
			}
			if (valid) {
				if (e.touchId != null && !active) {
					start(g.x, g.y, e.touchId);
					return true;
				}
			}
		}

		if (e.kind == EMove) {
			if (e.touchId != null && e.touchId == touchId) {
				movement(g.x, g.y);
				return true;
			}
		}

		if (e.kind == ERelease || e.kind == EReleaseOutside) {
			if (e.touchId == touchId && active) {
				end();
				return true;
			}
		}

		return false;
		#end
	}

	public var disabled(default, set) = false;

	function set_disabled(disabled) {
		if (disabled) {
			end();
		}

		return this.disabled = disabled;
	}

	public function start(x, y, touchID) {
		if (disabled) {
			return;
		}

		if (active) {
			return;
		}

		var currentTime = elk.Elk.instance.time;

		if (currentTime - tapTime < doubleTapTime) {
			doubleTapped = true;
		}

		tapTime = currentTime;

		this.x = x;
		this.y = y;
		this.touchId = touchID;
		mx = my = 0;
		dot.x = dot.y = 0;
		visible = true;
		active = true;
		eased_scale.value = 1.0;
		if (onActivate != null) {
			onActivate();
		}
	}

	public var disableDrag = false;

	public function movement(tx:Float, ty:Float) {
		if (disabled) {
			return;
		}

		var dx = tx - x;
		var dy = ty - y;
		var l = Math.sqrt(dx * dx + dy * dy);

		if (l > maxR && !disableDrag) {
			var fx = dx / l;
			var fy = dy / l;
			fx *= (maxR - l);
			fy *= (maxR - l);
			x -= fx;
			y -= fy;

			dx = tx - x;
			dy = ty - y;
			l = Math.sqrt(dx * dx + dy * dy);
		}

		if (l > 0) {
			mx = dx / l;
			my = dy / l;

			if (l > r) {
				dx = mx * r;
				dy = my * r;
			}
		} else {
			mx = my = dx = dy = 0;
		}

		magnitude = l / r;

		mx *= l / r;
		my *= l / r;

		if (magnitude < 0.5) {
			mx *= (1 - 2 * (0.5 - magnitude));
			my *= (1 - 2 * (0.5 - magnitude));
		}

		if (magnitude < 0.2) {
			mx = my = 0;
		}

		dot.x = Math.round(dx);
		dot.y = Math.round(dy);
	}

	var dz = 0.5;

	public function goingLeft() {
		return active && mx < -dz;
	}

	public function goingRight() {
		return active && mx > dz;
	}

	public function goingUp() {
		return active && my < -dz;
	}

	public function goingDown() {
		return active && my > dz;
	}

	override function sync(ctx:RenderContext) {
		super.sync(ctx);
		bg.setScale(eased_scale.value);
		dot.setScale(bg.scaleX);
	}

	public function end() {
		visible = false;
		active = false;
		doubleTapped = false;
		mx = my = magnitude = 0;
		eased_scale.value = .0;
		#if js
		touchId = null;
		#else
		touchId = 0;
		#end
	}
}
