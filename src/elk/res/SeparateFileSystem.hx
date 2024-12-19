package res;

import haxe.macro.Context;
import haxe.macro.Tools;

class SeparateFileSystem {
	#if macro
	#end
	public static function embedded(path:String) {
		#if !macro
		throw "Can only be used in macro";
		#end
	}
}
