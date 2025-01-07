package elk.db;

#if sys
import sys.db.Connection;

class Database {
	var connection:Connection;
	var migrations:Migrations;

	public function new() {
		sys.FileSystem.createDirectory('data');
		connection = sys.db.Sqlite.open('data/database.db');
		migrations = new Migrations(connection);
		migrations.migrate('db/migrations');
		Sys.println('Initialized DB');
	}
}
#else
class Database {
	public function new() {}
}
#end
