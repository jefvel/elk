package elk.gamestate;

class GameStateHandler extends elk.Process {
	public var current(default, set):GameState = null;

	var elk:Elk;

	public function new(elk:Elk) {
		super();
		this.elk = elk;
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
			elk.s2d.removeChild(current);
			current.onLeave();
			current = null;
		}

		newState.game = elk;
		elk.s2d.addChild(newState);
		newState.onEnter();

		return current = newState;
	}
}
