package elk.gamestate;

class GameStateHandler extends elk.Process {
	public var current(default, set):GameState = null;

	public function new() {
		super();
	}

	public override function tick(dt:Float) {
		if (current != null)
			current.tick(dt);
	}

	public override function update(dt:Float) {
		if (current != null)
			current.update(dt);
	}

	function set_current(newState:GameState) {
		if (current != null) {
			current.onRemove();
			current = null;
		}

		newState.game = elk.Elk.instance;
		newState.onEnter();

		return current = newState;
	}
}
