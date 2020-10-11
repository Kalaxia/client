tool
class_name AudioResource
extends Resource

export(Array, AudioStream) var audio_stream_array setget set_audio_stream_array
export(String) var text # subtitle

var _rng = RandomNumberGenerator.new()


func _init(audio_stream_array_p = []):
	audio_stream_array = audio_stream_array_p


func _ready():
	_rng.randomize()


func get_random_sound() -> AudioStream :
	if audio_stream_array == null or audio_stream_array.size() == 0:
		return null
	return audio_stream_array[_rng.randi_range(0, audio_stream_array.size() - 1)]


func set_audio_stream_array(new_audio_stream_array):
	audio_stream_array = new_audio_stream_array
	emit_signal("changed")


static func _set_loop_of_streams(audio_stream_array_p, loop_p):
	for stream in audio_stream_array_p:
		stream.set("loop", loop_p)
