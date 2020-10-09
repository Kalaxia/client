tool
class_name AudioStackingSingleSound, "res://resources/editor/audio_stacking.svg"
extends AudioStacking
# manager to play a single audio effect that stack (and do not cut)


func set_sound_resource(new_resource):
	if not new_resource is AudioStream:
		return
	sound_resource = new_resource
	for node in _audio_streams:
		node.stream = sound_resource


static func _node_play_sound(node, audio_resource, volume_dB = 0, pitch_scale = 1, bus = "Master"):
	node.stream = audio_resource
	node.volume_db = volume_dB
	node.pitch_scale = pitch_scale
	node.bus = bus
	node.play()
