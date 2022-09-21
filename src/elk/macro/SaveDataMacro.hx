package elk.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.TypeTools;

/*
 * Thanks to rudy on the haxe discord :)
 */
class SaveDataMacro {
	public static function build() {
		var cls = Context.getLocalClass();
		var t = Context.getLocalType();
		var ct = TypeTools.toComplexType(t);
		var path = switch (ct) {
			case TPath(path): path;
			case _: throw "INCORRECT";
		}

		return Context.getBuildFields().concat((macro class Foo {
			static var _current:$ct;

			/**
			 * resets the current saveslot
			 */
			public static function reset() {
				var saveSlot = 0;
				if (_current != null) {
					saveSlot = _current.saveSlot;
				}
				_current = null;

				return getCurrent(saveSlot);
			}

			/**
			 * gets current actual save by saveslot.
			 * if saveslot is changed, it'll load it/create a new one
			 * and discard the current save
			 * @param saveSlot = 0 
			 * @return $ct
			 */
			public static function getCurrent(saveSlot = 0):$ct {
				if (_current == null) {
					_current = new $path();
					_current = _current.load(_current, saveSlot);
				}
				return _current;
			}
		}).fields);
	}
}
