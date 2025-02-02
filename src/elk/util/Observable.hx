package elk.util;

class Observable<T> {
	var listeners : Array<T -> Void> = [];

	public function new() {}

	public function addListener(cb : T -> Void) {
		if( listeners.contains(cb) ) return;
		listeners.push(cb);
	}

	public function clearListeners() {
		listeners = [];
	}

	public function removeListener(cb : T -> Void) {
		return listeners.remove(cb);
	}

	public function emit(e : T) {
		for (cb in listeners) cb(e);
	}
}
