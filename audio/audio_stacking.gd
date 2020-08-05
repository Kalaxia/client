class_name AudioStacking, "res://resources/editor/audio_stacking.svg"
extends Node
# manager to play a single audio effect that stack (and do not cut)

signal soundFinished()

export(int) var max_audio_playback = 2 setget set_max_audio_playback
export(AudioStream) var sound_ressource setget set_sound_ressource
# if this is true is a new sound is tried to be played but we have already max_audio_playback sonds playing then the oldest sond is stoped and a new one is played in its stead
export(bool) var override_sound = false 

var _audio_streams = [] setget private_set


func _ready():
	_add_audio_stream()


func private_set(new_varaible):
	pass # cannot set from outside


func play_sound(volume_dB = 0, pitch_scale = 1, bus = "Master"):
	for node in _audio_streams:
		if node is AudioStreamPlayer and not node.playing:
			_node_play_sound(node, volume_dB, pitch_scale, bus)
			return true
	if _audio_streams.size() < max_audio_playback:
		_node_play_sound(_add_audio_stream(), volume_dB, pitch_scale, bus)
		return true
	if not override_sound:
		return false
	_override_sound(_audio_streams, volume_dB, pitch_scale, bus)
	return true


func stop_sound():
	for node in _audio_streams:
		if node is AudioStreamPlayer:
			node.stop()


func set_sound_ressource(new_ressource: AudioStream):
	sound_ressource = new_ressource
	sound_ressource.loop = false
	for node in _audio_streams:
		node.stream = sound_ressource


func set_max_audio_playback(new_number: int):
	if new_number <= 0:
		return
	if new_number < max_audio_playback:
		while _audio_streams.size() > new_number:
			var node = _audio_streams.pop_back()
			node.stop()
			node.queue_free()
	max_audio_playback = new_number


static func _override_sound(audio_streams, volume_dB = 0, pitch_scale = 1, bus = "Master"):
	# search for the node with the greater playback position and restart the sound
	var audio_stream_player = audio_streams[0]
	var max_playback_pos = audio_stream_player.get_playback_position()
	for node in audio_streams:
		if node.get_playback_position() > max_playback_pos:
			max_playback_pos = node.get_playback_position()
			audio_stream_player = node
	_node_play_sound(audio_stream_player, volume_dB, pitch_scale, bus)


func _on_finished():
	emit_signal("soundFinished")


func _add_audio_stream():
	var audio_stream_player = AudioStreamPlayer.new()
	audio_stream_player.stream = sound_ressource
	_audio_streams.push_back(audio_stream_player)
	add_child(audio_stream_player)
	audio_stream_player.connect("finished",self,"_on_finished")
	return audio_stream_player


static func _node_play_sound(node, volume_dB = 0, pitch_scale = 1, bus = "Master"):
	node.volume_db = volume_dB
	node.pitch_scale = pitch_scale
	node.bus = bus
	node.play()
