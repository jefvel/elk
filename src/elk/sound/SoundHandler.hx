package elk.sound;

import hxd.snd.SoundGroup;
import hxd.snd.ChannelGroup;
import hxd.snd.Channel;

class SoundHandler {
	public var musicVolume(get, set): Float;
	public var sfxVolume(get, set): Float;
	
	public var sfxChannel: ChannelGroup;
	public var musicChannel: ChannelGroup;

	public function new() {
		sfxChannel = new ChannelGroup("sfx");
		musicChannel = new ChannelGroup("music");
	}
	
	public function playSound(sound: hxd.res.Sound, volume = 0.5, loop = false, soundGroup: SoundGroup = null) {
		return sound.play(loop, volume, sfxChannel, soundGroup);
	}

	public function playMusic(sound: hxd.res.Sound, volume = 0.5, loop = true, soundGroup: SoundGroup = null) {
		return sound.play(loop, volume, musicChannel, soundGroup);
	}

	function get_sfxVolume()
		return sfxChannel.volume;

	function set_sfxVolume(volume:Float)
		return sfxChannel.volume = volume;

	function get_musicVolume()
		return musicChannel.volume;

	function set_musicVolume(volume:Float)
		return musicChannel.volume = volume;
}