tool
class_name AudioStacking, "res://resources/editor/audio_stacking.svg"
extends Node
# manager to play a single audio effect that stack (and do not cut)

signal sound_finished()

export(int) var max_audio_playback = 2 setget set_max_audio_playback
export(Resource) var sound_resource setget set_sound_resource # AudioResource
# if this is true is a new sound is tried to be played but we have already max_audio_playback sonds playing then the oldest sond is stoped and a new one is played in its stead
export(bool) var override_sound = false 
export(String) var default_bus = "Master"
export(float, -100.0, 0.0) var default_volume = 0.0
export(float, 0.0, 4.0) var default_pitch_scale = 1.0
# todo mix target

var playing_in_editor = false setget set_playing_in_editor # only use in editor, has no effect ingame
var _audio_streams = [] setget private_set


func _ready():
	if Engine.editor_hint:
		update_configuration_warning()
	else:
		_add_audio_stream()


func _notification(what):
	if Engine.editor_hint:
		match what:
			NOTIFICATION_PARENTED, NOTIFICATION_UNPARENTED:
				update_configuration_warning()


func _get_configuration_warning():
	
	if not Engine.editor_hint:
		return ""
	for node in get_children():
		if _is_node_compatible_stream_player(node) and not _audio_streams.has(node):
			return "The node should not have AudioStreamPlayer attached, " \
					+ "the player wont be considered by the manager."
	return ""


func _get_property_list():
	return [{
		"name" : "playing_in_editor",
		"type" : TYPE_BOOL,
		"usage" : PROPERTY_USAGE_EDITOR,
	}]

func private_set(_new_varaible):
	pass # cannot set from outside


func play_sound(volume_dB = default_volume, pitch_scale = default_pitch_scale, bus = default_bus):
	for node in _audio_streams:
		if _is_node_compatible_stream_player(node) and not node.playing:
			_node_play_sound(node, sound_resource, volume_dB, pitch_scale, bus)
			return true
	if _audio_streams.size() < max_audio_playback:
		_node_play_sound(_add_audio_stream(), sound_resource, volume_dB, pitch_scale, bus)
		return true
	if not override_sound:
		return false
	_override_sound(_audio_streams, sound_resource, volume_dB, pitch_scale, bus)
	return true


func stop_sound():
	for node in _audio_streams:
		if _is_node_compatible_stream_player(node):
			node.stop()


func set_sound_resource(new_resource: Resource):
	if new_resource != null and new_resource is AudioResource:
		sound_resource = new_resource


func set_max_audio_playback(new_number: int):
	if new_number <= 0:
		return
	if new_number < max_audio_playback:
		while _audio_streams.size() > new_number:
			var node = _audio_streams.pop_back()
			node.stop()
			node.queue_free()
	max_audio_playback = new_number


static func _override_sound(audio_streams, audio_resource, volume_dB = default_volume, pitch_scale = default_pitch_scale, bus = default_bus):
	# search for the node with the greater playback position and restart the sound
	var audio_stream_player = audio_streams[0]
	var max_playback_pos = audio_stream_player.get_playback_position()
	for node in audio_streams:
		if node.get_playback_position() > max_playback_pos:
			max_playback_pos = node.get_playback_position()
			audio_stream_player = node
	_node_play_sound(audio_stream_player, audio_resource, volume_dB, pitch_scale, bus)


func _on_finished():
	emit_signal("sound_finished")


func _add_audio_stream():
	var audio_stream_player = AudioStreamPlayer.new()
	_audio_streams.push_back(audio_stream_player)
	add_child(audio_stream_player)
	audio_stream_player.connect("finished", self, "_on_finished")
	return audio_stream_player


static func _node_play_sound(node, audio_resource, volume_dB = 0, pitch_scale = 1, bus = "Master"):
	node.stream = audio_resource.get_random_sound()
	node.volume_db = volume_dB
	node.pitch_scale = pitch_scale
	node.bus = bus
	node.play()


static func _is_node_compatible_stream_player(node):
	return node is AudioStreamPlayer


# editor only code
func set_playing_in_editor(new_bool):
	if Engine.editor_hint:
		playing_in_editor = new_bool
		if playing_in_editor:
			var node = _audio_streams[0] if _audio_streams.size() > 0 else _add_audio_stream()
			_node_play_sound(node, sound_resource, default_volume, default_pitch_scale, default_bus)
			node.connect("finished", self, "_on_sound_finished_editor", [], CONNECT_ONESHOT)
		else:
			while _audio_streams.size() > 0:
				var node = _audio_streams.pop_back()
				node.playing = false
				node.queue_free()
		property_list_changed_notify()


func _on_sound_finished_editor():
	self.playing_in_editor = false
