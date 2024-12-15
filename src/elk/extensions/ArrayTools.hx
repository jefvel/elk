package elk.extensions;

class ArrayTools {
	static public function randomElement<T>(a:Array<T>):T {
		if (a.length == 0) {
			return null;
		}
		return a[Std.int(Math.random() * a.length)];
	}

	static public function find<T>(a:Array<T>, search:(T) -> Bool):T {
		for (i in a) {
			if (search(i))
				return i;
		}

		return null;
	}
}
