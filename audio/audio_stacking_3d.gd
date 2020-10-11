tool
class_name AudioStacking3D, "res://resources/editor/audio_stacking_3d.svg"
extends AudioStacking2D


func _add_audio_stream():
	var audio_stream_player = AudioStreamPlayer3D.new()
	_audio_streams.push_back(audio_stream_player)
	add_child(audio_stream_player)
	audio_stream_player.connect("finished", self, "_on_finished")
	return audio_stream_player


static func _node_play_sound(node: AudioStreamPlayer3D, audio_resource, volume_dB = 0, pitch_scale = 1, bus = "Master"):
	node.stream = audio_resource.get_random_sound()
	node.unit_db = volume_dB
	node.pitch_scale = pitch_scale
	node.bus = bus
	node.play()


static func _is_node_compatible_stream_player(node):
	return node is AudioStreamPlayer3D
