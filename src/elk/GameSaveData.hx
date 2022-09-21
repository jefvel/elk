package elk;

import hxd.Save;

/**
 	you can extend and fill this with whatever data needs saving.

	**Example:**
	```haxe
	class SaveData extends GameSaveData {
		public var value = 0;
	}
	
	var data = SaveData.getCurrent();
	data.value = 1000;

	data.save();
	```
**/
@:autoBuild(elk.macro.SaveDataMacro.build())
class GameSaveData {
	static var SALT:String = "S!!!A***L*TTT";

	public function new() {}
	
	public var saveSlot = 0;
	
	static inline final saveNamespace = haxe.macro.Compiler.getDefine("saveNamespace");

	#if debug
	static inline final hash = false;
	static inline final baseSaveName = '${saveNamespace}_debug';
	#else
	static inline final hash = true;
	static inline final baseSaveName = saveNamespace;
	#end
	
	var saveName(get, null): String;
	function get_saveName() {
		return '$baseSaveName-$saveSlot';
	}

	/**
	 * saves data to disk/localstorage
	 */
	public function save() {
		try {
			var data = serialize();
			try if( Save.readSaveData(this.saveName) == data ) return false catch( e : Dynamic ) {};
			Save.writeSaveData(this.saveName, data);
			return true;
		} catch (e) {
			trace(e);
			return false;
		}
	}

	public function load(defVal: Dynamic = null, saveSlot = 0) {
		this.saveSlot = saveSlot;
		try {
			return deserialize(Save.readSaveData(saveName), defVal);
		} catch( e : Dynamic ) {
			return defVal;
		}
	}


	static function makeCRC( data : String ) {
		return haxe.crypto.Sha1.encode(data + haxe.crypto.Sha1.encode(data + SALT)).substr(4, 32);
	}
	
	/**
	 * returns serialized savedata as string
	 * @return String
	 */
	@:noCompletion public function serialize(): String {
		var data = haxe.Serializer.run(this);
		return hash ? data + "#" + makeCRC(data) : data;
	}
	
	/**
	 * load serialized savedata from string,
	 * returns savedata object
	 * @param data 
	 */
	@:noCompletion public function deserialize(data: String, defValue: Dynamic) {
		if( hash ) {
			if( data.charCodeAt(data.length - 33) != '#'.code )
				throw "Missing CRC";
			var crc = data.substr(data.length - 32);
			data = data.substr(0, -33);
			if( makeCRC(data) != crc )
				throw "Invalid CRC";
		}
		var obj : Dynamic = haxe.Unserializer.run(data);

		// set all fields that were not set to default value (auto upgrade)
		if( defValue != null && Reflect.isObject(obj) && Reflect.isObject(defValue) ) {
			for( f in Reflect.fields(defValue) ) {
				if( Reflect.hasField(obj, f) ) continue;
				Reflect.setField(obj, f, Reflect.field(defValue,f));
			}
		}

		return obj;
	}
	
	function writeSaveData(data: String) {
		#if sys
		sys.io.File.saveContent(saveName+".sav", data);
		#elseif js
		js.Browser.window.localStorage.setItem(name, data);
		#else
		throw "Not implemented";
		#end
	}
}	
