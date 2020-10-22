extends PanelContainer

const ASSETS = preload("res://resources/assets.tres")

export(Resource) var player setget set_player

onready var label = $MarginContainer/VBoxContainer/PanelContainer/Label
onready var texture = $MarginContainer/VBoxContainer/HBoxContainer/CircularFrame/TextureRect
onready var frame = $MarginContainer/VBoxContainer/HBoxContainer/CircularFrame
onready var margin_container = $MarginContainer


func _ready():
	_update_player_element()


func set_player(new_player):
	player = new_player
	_update_player_element()


func _update_player_element():
	if label == null or texture == null or frame == null:
		return
	margin_container.visible = player != null
	if player != null:
		label.text = player.username
		#texture.texture = player.avatar
		frame.color = player.faction.get_color()
