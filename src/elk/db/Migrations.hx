package elk.db;

#if sys
import sys.db.Connection;

class Migrations {
	var connection: Connection;

	public function new(connection: Connection) {
		this.connection = connection;
		initialize();
	}

	public function initialize() {
		final initialization_query = ' -- Create Migrations Table
			CREATE TABLE IF NOT EXISTS migrations (
				id INTEGER PRIMARY KEY AUTOINCREMENT,
				name TEXT NOT NULL UNIQUE,
				ran_at DATETIME DEFAULT CURRENT_TIMESTAMP
			)	
		';

		connection.request(initialization_query);
	}

	function has_ran_migration(name: String) {
		var res = connection.request('
			SELECT * FROM migrations
			WHERE name = \'${connection.escape(name)}\'
		');

		return res.length > 0;
	}

	function mark_as_ran(name: String) {
		var res = connection.request('
			INSERT INTO migrations(name)
			VALUES(\'${connection.escape(name)}\')
		');
	}

	public function migrate(migration_dir: String) {
		connection.startTransaction();
		var files = hxd.Res.loader.dir(migration_dir);
		files.sort((a, b) -> {
			if (a.entry.name < b.entry.name) return -1;
			return 1;
		});
		for (file in files) {
			var is_up = StringTools.endsWith(file.name, '.up.sql');
			if (!is_up) continue;

			var name = file.name.split('.')[0];
			var has_been_run = has_ran_migration(name);
			if (has_been_run) continue;

			var content = file.toText();
			var queries = content.split(';');
			for (q in queries) {
				connection.request(q);
			}

			mark_as_ran(name);
			Sys.println('Ran migration $name');
		}

		connection.commit();
	}
}
#end
