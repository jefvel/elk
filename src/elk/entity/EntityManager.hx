package elk.entity;

import elk.util.Observable;

class EntityManager extends elk.Process {
	public static var instance : EntityManager;

	public var entities : Array<Entity> = [];
	public var onEntityAdded : Observable<Entity> = new Observable();
	public var onEntityRemoved : Observable<Entity> = new Observable();

	public function new() {
		super();
		instance = this;
	}

	public function add(e : Entity) {
		if( entities.contains(e) ) return;
		entities.push(e);
		onEntityAdded.emit(e);
	}

	public function remove(e : Entity) {
		if( entities.remove(e) ) {
			onEntityRemoved.emit(e);
		}
	}

	public override function tick(dt : Float) {
		for (e in entities) {
			e.preTick();
		}
		for (e in entities) {
			e.tick(dt);
		}
	}

	public function render(elapsed : Float) {
		for (e in entities) e.render(elapsed);
	}
}
