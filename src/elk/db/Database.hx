package elk.db;

#if sys
import sys.db.Connection;
#end

enum DatabaseType {
	SQLite;
	MySQL;
}

typedef DatabaseOptions = {
	var type:DatabaseType;
	var ?file:String;

	// MySQL
	var ?database:String;
	var ?user:String;
	var ?pass:String;
	var ?socket:String;
	var ?port:Int;
	var ?host:String;
}

final default_options:DatabaseOptions = {
	type: SQLite,
}

#if sys
class Database {
	var type:DatabaseType = SQLite;

	var connection:Connection;
	var migrations:Migrations;

	#if (target.threaded)
	#end
	public function new(?options:DatabaseOptions) {
		options = options ?? default_options;
		switch (options.type) {
			case SQLite:
				init_sqlite(options.file ?? 'data/database.db');
			case MySQL:
				init_mysql(options);
		}

		migrations = new Migrations(connection);
		migrations.migrate('db/migrations');
		Sys.println('Initialized DB');
	}

	function init_sqlite(file_name:String) {
		var dir = haxe.io.Path.directory(file_name);
		sys.FileSystem.createDirectory(dir);
		connection = sys.db.Sqlite.open(file_name);
	}

	function init_mysql(options:DatabaseOptions) {
		connection = sys.db.Mysql.connect({
			host: options.host,
			socket: options.socket,
			user: options.user,
			database: options.database,
			pass: options.pass,
			port: options.port,
		});
	}

	public function close() {
		if (connection == null)
			return;
		connection.close();
		connection = null;
		Sys.println("Closed DB connection.");
	}
}
#else
class Database {
	public function new(?options:DatabaseOptions) {}
}
#end
