tool
class_name AudioStacking2D, "res://resources/editor/audio_stacking_2d.svg"
extends AudioStacking


func play_sound_positioned(position, volume_dB = default_volume, pitch_scale = default_pitch_scale, bus = default_bus):
	for node in _audio_streams:
		if _is_node_compatible_stream_player(node) and not node.playing:
			_node_play_sound_positioned(node, sound_resource, position, volume_dB, pitch_scale, bus)
			return true
	if _audio_streams.size() < max_audio_playback:
		_node_play_sound_positioned(_add_audio_stream(), sound_resource, position, volume_dB, pitch_scale, bus)
		return true
	if not override_sound:
		return false
	_override_sound_positioned(_audio_streams, sound_resource, position, volume_dB, pitch_scale, bus)
	return true


func _add_audio_stream():
	var audio_stream_player = AudioStreamPlayer2D.new()
	_audio_streams.push_back(audio_stream_player)
	add_child(audio_stream_player)
	audio_stream_player.connect("finished", self, "_on_finished")
	return audio_stream_player


static func _override_sound_positioned(audio_streams, audio_resource, position, volume_dB = default_volume, pitch_scale = default_pitch_scale, bus = default_bus):
	# search for the node with the greater playback position and restart the sound
	var audio_stream_player = audio_streams[0]
	var max_playback_pos = audio_stream_player.get_playback_position()
	for node in audio_streams:
		if node.get_playback_position() > max_playback_pos:
			max_playback_pos = node.get_playback_position()
			audio_stream_player = node
	_node_play_sound_positioned(audio_stream_player, audio_resource, position, volume_dB, pitch_scale, bus)


static func _is_node_compatible_stream_player(node):
	return node is AudioStreamPlayer2D


static func _node_play_sound_positioned(node, audio_resource, position, volume_dB = 0, pitch_scale = 1, bus = "Master"):
	node.position = position
	_node_play_sound(node, audio_resource, volume_dB, pitch_scale, bus)
