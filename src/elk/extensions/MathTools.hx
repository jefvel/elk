package elk.extensions;

class MathTools {
	static public function clamp(a:Float, min:Float, max:Float):Float {
		if (a < min) {
			return min;
		}
		if (a > max) {
			return max;
		}
		return a;
	}

	static public inline function mod(a:Float, n:Float) {
		return a - Math.floor(a / n) * n;
	}

	static public function angleBetween(radian:Float, toRadian:Float):Float {
		var tau = Math.PI * 2;
		var a = mod(radian - toRadian, tau);
		var b = mod(toRadian - radian, tau);

		return a < b ? -a : b;
	}

	public static function toFixed(number:Float, ?precision = 2):Float {
		number *= Math.pow(10, precision);
		return Math.round(number) / Math.pow(10, precision);
	}

	static function formatMoneyString(s:String) {
		var r = ~/(\d)(?=(\d{3})+(?!\d))/g;
		return r.replace(s, "$1 ");
	}

	static public function toMoneyString(a:Int):String {
		return formatMoneyString('$a');
	}

	static public function sign(a:Float):Float {
		if (a < 0)
			return -1;
		return 1;
	}

	static public function toMoneyStringFloat(x:Float):String {
		var parts = '${x.toFixed()}'.split(".");
		parts[0] = formatMoneyString(parts[0]);
		if (parts.length == 1)
			parts.push('00');
		return parts.join(".");
	}

	/**
		formats seconds to mm:ss
	**/
	static public function toTimeString(x:Float, noHundreds = false):String {
		var minutes = Math.floor(x / 60);
		var seconds = x - minutes * 60;
		var extraZero = minutes < 10 ? '0' : '';
		var extraSecondZero = seconds < 10 ? '0' : '';
		var hundredsSplit = '${seconds}'.split('.');
		var hundreds = "000";

		var hours = Std.int(minutes / 60);
		minutes -= hours * 60;
		var hourText = "";
		if (hours >= 10) {
			hourText = '$hours:';
		} else if (hours > 0) {
			hourText = '0$hours:';
		}

		if (noHundreds) {
			return '$extraZero$minutes:$extraSecondZero${Math.floor(seconds)}';
		}

		if (hundredsSplit.length > 1) {
			hundreds = '${hundredsSplit[1].substr(0, 3)}';
			while (hundreds.length < 3) {
				hundreds = "0" + hundreds;
			}
		}

		return '$hourText$extraZero$minutes:$extraSecondZero${Math.floor(seconds)}:$hundreds';
	}
}
