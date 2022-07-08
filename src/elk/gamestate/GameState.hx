package elk.gamestate;

import h2d.Object;

class GameState {
	public var s2d: Object = null;
	public var s3d: h3d.scene.Object = null;
	public var game: elk.Elk = null;

	public function new() {
		s2d = new Object();
		s3d = new h3d.scene.Object();
		game = elk.Elk.instance;
	}
	
	/**
	 * update runs at every frame, with a variable timestep
	 * @param dt time since last frame
	 */
	public function update(dt: Float) {
	}
	
	/**
	 * tick runs at a fixed timestep, so dt will be constant
	 * @param dt time since last tick
	 */
	public function tick(dt: Float) {
	}
	
	public function onEnter() {
		game.s2d.addChild(s2d);
		game.s3d.addChild(s3d);
	}

	public function onRemove() {
		s2d.remove();
		s3d.remove();
	}
}