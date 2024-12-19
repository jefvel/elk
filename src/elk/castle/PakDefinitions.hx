package elk.castle;

class PakDefinitions {
	public static function get_cdb_pak_definitions() {
		var cdb = sys.io.File.getContent('res/data.cdb');
		var json:{
			sheets:Array<{
				name:String,
				lines:Array<{
					ID:String,
					Directories:Array<{
						Directory:String,
					}>,
					Files:Array<{
						File:String,
					}>,
					Embed:Bool,
				}>
			}>
		} = haxe.Json.parse(cdb);

		var sheet = null;
		for (s in json.sheets) {
			if (s.name == 'pak_config') {
				sheet = s;
				break;
			}
		}

		if (sheet == null)
			return null;

		var sub_paks = [];
		var embedded_paths = [];
		for (row in sheet.lines) {
			if (row.Embed) {
				for (dir in row.Directories ?? [])
					embedded_paths.push(dir.Directory);
				for (file in row.Files ?? [])
					embedded_paths.push(file.File);
			} else {
				var included_paths = [];
				for (dir in row.Directories ?? [])
					included_paths.push(dir.Directory);
				for (file in row.Files ?? [])
					included_paths.push(file.File);
				sub_paks.push({
					name: row.ID,
					included_paths: included_paths,
				});
			}
		}

		return {
			embedded_paths: embedded_paths,
			named_paks: sub_paks,
		}
	}
}
