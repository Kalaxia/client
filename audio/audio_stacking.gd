extends Node

# manager to play a single audio effect that stack (and do not cut)

class_name AudioStacking


export(int) var max_audio_playback = 2 setget set_max_audio_playback
var _audio_streams = [] setget private_set
export(AudioStream) var sound_ressource setget set_sound_ressource
# if this is true is a new sound is tried to be played but we have already max_audio_playback sonds playing then the oldest sond is stoped and a new one is played in its stead
export(bool) var override_sound = false 

signal soundFinished()

func _ready():
	var node
	if has_node("AudioStreamPlayer") && $AudioStreamPlayer is AudioStreamPlayer:
		node = $AudioStreamPlayer
	else:
		node = AudioStreamPlayer.new()
		add_child(node)
	node.stream = sound_ressource
	node.connect("finished",self,"_on_finished")
	_audio_streams.push_back(node)
	pass

func _on_finished():
	emit_signal("soundFinished")

func private_set(new_varaible):
	pass # cannot set from outside

func play_sound(volume_dB =0, pitch_scale = 1,bus = "Master"):
	for i in _audio_streams:
		if ! i.playing:
			i.volume_db = volume_dB
			i.pitch_scale = pitch_scale
			i.bus = bus
			i.play()
			return true
	if _audio_streams.size() < max_audio_playback:
		var audio_stream_player = AudioStreamPlayer.new()
		_audio_streams.push_back(audio_stream_player)
		add_child(audio_stream_player)
		audio_stream_player.connect("finished",self,"_on_finished")
		audio_stream_player.volume_db = volume_dB
		audio_stream_player.pitch_scale = pitch_scale
		audio_stream_player.bus = bus
		audio_stream_player.play()
		return true
	if !override_sound:
		return false
	var audio_stream_player = _audio_streams[0]
	var max_playback_pos = audio_stream_player.get_playback_position()
	for i in _audio_streams:
		if i.get_playback_position() > max_playback_pos:
			max_playback_pos = i.get_playback_position()
			audio_stream_player = i
	audio_stream_player.volume_db = volume_dB
	audio_stream_player.pitch_scale = pitch_scale
	audio_stream_player.bus = bus
	audio_stream_player.play()
	return true
	
func stop_sound():
	for i in _audio_streams:
		i.stop()

func set_sound_ressource(new_ressource: AudioStream):
	sound_ressource = new_ressource.duplicate()
	sound_ressource.loop = false
	for i in _audio_streams:
		i.stream = sound_ressource

func set_max_audio_playback(new_number: int):
	if new_number <= 0:
		return
	if new_number < max_audio_playback:
		while _audio_streams.size() > new_number:
			var node = _audio_streams.pop_back()
			node.stop()
			node.queue_free()
	max_audio_playback = new_number
	
