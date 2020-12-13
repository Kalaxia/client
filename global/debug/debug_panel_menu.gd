extends VBoxContainer

const GAME_DATA_DUMP_PATH = "res://game_data.tres"

onready var button_dump = $MarginContainer/VBoxContainer/Button


func _ready():
	print_stack()
	button_dump.connect("pressed", self, "_dump_game_data")


func _dump_game_data():
	if Store.game_data != null:
		ResourceSaver.save(GAME_DATA_DUMP_PATH, Store.game_data)
