extends Node

signal building_finished_audio(building)
signal ship_queue_finished_audio(ship_queue)

const AUDIO_SCENE_SINGLETON = preload("res://audio/audio_scene_singleton.tscn")

var audio_scene


func _init():
	var node = AUDIO_SCENE_SINGLETON.instance()
	add_child(node)
	audio_scene = node


func play_click():
	audio_scene.play_click()


func building_constructed_audio(building):
	emit_signal("building_finished_audio", building)


func ship_queue_finished_audio(ship_group):
	emit_signal("ship_queue_finished_audio", ship_group)
