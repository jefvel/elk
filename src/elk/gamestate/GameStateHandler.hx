package elk.gamestate;

class GameStateHandler extends elk.Process {
	public var current(get, null):GameState;

	private var _current:GameState = null;

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

	public function change(new_state:GameState) {
		var current = _current;
		if (current != null) {
			elk.s2d.removeChild(current);
			current.on_leave();
			current = null;
		}

		new_state.game = elk;
		elk.s2d.addChild(new_state);
		new_state.on_enter();

		return _current = new_state;
	}

	function get_current():GameState {
		return _current;
	}
}
