class_name PlayerInfoFactionColumn
extends PanelContainer

const ASSETS = preload("res://resources/assets.tres")

var player : Player setget set_player

onready var label = $Label


func _ready():
	update_display()


func update_player(new_player):
	set_player(new_player)


func set_player(new_player):
	player =  new_player
	update_display()


func _set_is_ready(is_ready : bool):
	label.add_color_override("font_color", Color(1.0, 1.0, 1.0) if is_ready else Color(0.6, 0.6, 0.6))


func get_username():
	return tr("general.unkown_username") if (player.username == "") else player.username


func update_display():
	if label == null:
		return
	label.text = get_username()
	_set_is_ready(player.ready)
	_update_faction_color()


func _update_faction_color():
	var style = get("custom_styles/panel")
	var style_used = style if style != null else StyleBoxFlat.new()
	if player.faction != null and player.faction.id as int != 0:
		style_used.border_color = player.faction.get_color()
	else:
		style_used.border_color = Color(0.12, 0.12, 0.12, 0.5)
	set("custom_styles/panel", style_used)
