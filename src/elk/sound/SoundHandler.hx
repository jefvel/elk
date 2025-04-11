package elk.sound;

import hxd.snd.SoundGroup;
import hxd.snd.ChannelGroup;
import hxd.snd.Channel;

class SoundHandler {
	public var musicVolume(get, set) : Float;
	public var sfxVolume(get, set) : Float;

	public var sfxChannel : ChannelGroup;
	public var musicChannel : ChannelGroup;

	public function new() {
		sfxChannel = new ChannelGroup("sfx");
		musicChannel = new ChannelGroup("music");
	}

	public function playSound(sound : hxd.res.Sound, volume = 0.5, loop = false, soundGroup : SoundGroup = null) {
		return sound.play(loop, volume, sfxChannel, soundGroup);
	}

	public function playSoundPitch(snd : hxd.res.Sound, volume = 0.5, pitch = 1.0, loop = false, soundGroup : SoundGroup = null) {
		var sound = snd.play(loop, volume, sfxChannel, soundGroup);
		sound.addEffect(new hxd.snd.effect.Pitch(pitch));
		return sound;
	}

	public function playMusic(sound : hxd.res.Sound, volume = 0.5, loop = true, soundGroup : SoundGroup = null) {
		return sound.play(loop, volume, musicChannel, soundGroup);
	}

	/**
	 * plays wobbly sound effect with random pitch
	 * @param snd
	 * @param volume = 0.3
	 */
	public function playWobble(snd : hxd.res.Sound, volume = 0.3, wobbleAmount = 0.1, loop = false, soundGroup : SoundGroup = null) {
		var sound = snd.play(loop, volume, sfxChannel, soundGroup);
		sound.addEffect(new hxd.snd.effect.Pitch(1 - wobbleAmount + Math.random() * (wobbleAmount * 2)));
		return sound;
	}

	function get_sfxVolume()
		return sfxChannel.volume;

	function set_sfxVolume(volume : Float)
		return sfxChannel.volume = volume;

	function get_musicVolume()
		return musicChannel.volume;

	function set_musicVolume(volume : Float)
		return musicChannel.volume = volume;
}
