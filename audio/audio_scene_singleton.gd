class_name AudioSceneSingleton
extends Node

onready var click_sound = $AudioStackingClick


func play_click():
	if click_sound != null:
		click_sound.play_sound()
