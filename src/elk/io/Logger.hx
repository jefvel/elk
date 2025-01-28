package elk.io;

class Logger {
	static inline function print(msg : String) {
		#if sys
		Sys.println(msg);
		#else
		trace(msg);
		#end
	}

	public static function info(msg) {
		print('INFO: $msg');
	}

	public static function warn(msg) {
		print('WARNING: $msg');
	}

	public static function error(msg) {
		print('ERROR: $msg');
	}

	public static function success(msg) {
		print('SUCCESS: $msg');
	}

	public static function debug(msg) {
		print('DEBUG: $msg');
	}
}
