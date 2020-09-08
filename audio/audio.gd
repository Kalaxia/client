class_name AudioSceneSingleton
extends Node

const AUDIO_SCENE_SINGLETON = preload("res://audio/audio_scene_singleton.tscn")

var audio_scene


func _init():
	var node = AUDIO_SCENE_SINGLETON.instance()
	add_child(node)
	audio_scene = node


func play_click():
	audio_scene.play_click()
	pass
