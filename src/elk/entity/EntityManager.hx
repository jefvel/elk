package elk.entity;

class EntityManager extends elk.Process {
	public var entities: Array<Entity> = [];
	public function new() {
		
	}
	
	public function add(e:Entity) {
		entities.push(e);
	}
	
	public override function tick(dt:Float) {
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