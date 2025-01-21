package elk.io;

class CommandLineInput {
	var cmd = '';

	function reset_command() {
		Sys.print('> ');
		cmd = '';
	}

	var pressed_arrow = false;

	function write_csi(code: String) {
		var out = Sys.stdout();
		out.writeByte(0x1B);
		out.writeString('[');
		out.writeString(code);
	}

	public function log(message: String) {
		write_csi('s');
		write_csi('1E');
		write_csi('1L');
		var time = Date.now();
		var time_str = '${time.getHours()}:${time.getMinutes()}:${time.getSeconds()}';
		Sys.println('[$time_str] $message');

		write_csi('1E');
		refresh_line();
		write_csi('u');
	}

	function refresh_line() {
		Sys.print('> ' + cmd);
	}

	function input_thread_loop() {
		reset_command();
		while (running) {
			var code = Sys.getChar(false);
			if (code == 224) pressed_arrow = true;

			if (code == 0x03) exit();
			else if (code == 0x08) { // backspace
				if (cmd.length > 0) {
					cmd = cmd.substr(0, cmd.length - 1);
					// Sys.stdout().writeByte(code);
					Sys.stdout().writeByte(0x08);
					write_csi('X');
				}
			}
			else if (code == 0x0D) {
				Sys.stdout().writeByte(0x0D);
				Sys.println('> ' + cmd);
				/*
					if (cmd.length != 0)
						Sys.println('ran command $cmd');
				 */
				if (cmd == 'exit') exit();

				reset_command();
			}
			else if (code >= 32 && code < 128) {
				if (pressed_arrow) {
					pressed_arrow = false;
					switch (String.fromCharCode(code)) {
						case 'K': // left
							write_csi('1D');
						case 'M': // right
							write_csi('1C');
						case 'H': // up
						case 'P': // down
					}
				}
				else {
					var char = String.fromCharCode(code);
					cmd += char;
					Sys.stdout().writeByte(code);
				}
			}
		}
	}
}
