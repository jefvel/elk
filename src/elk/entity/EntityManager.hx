package elk.entity;

class EntityManager extends elk.Process {
	public static var instance : EntityManager;

	public var entities : Array<Entity> = [];

	public function new() {
		super();
		instance = this;
	}

	public function add(e : Entity) {
		entities.push(e);
	}

	public function remove(e : Entity) {
		entities.remove(e);
	}

	public override function tick(dt : Float) {
		for (e in entities) {
			e.preTick();
		}
		for (e in entities) {
			e.tick(dt);
		}
	}

	public function render() {
		for (e in entities) e.render();
	}
}
