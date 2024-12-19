package elk.gamestate;

import h2d.Object;

class GameState extends h2d.Object {
	public var game:elk.Elk = null;

	public function new(?p) {
		super(p);
		game = elk.Elk.instance;
	}

	/**
	 * update runs at every frame, with a variable timestep
	 * @param dt time since last frame
	 */
	public function update(dt:Float) {}

	/**
	 * tick runs at a fixed timestep, so dt will be constant
	 * @param dt time since last tick
	 */
	public function tick(dt:Float) {}

	public function onEnter() {}

	public function onLeave() {}
}
