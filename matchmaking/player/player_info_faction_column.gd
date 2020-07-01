extends PanelContainer

class_name PlayerInfoFactionColumn

var player setget set_player

func update_player(player):
	set_player(player)

func set_player(new_player):
	player =  new_player
	update_display()

func _set_is_ready(is_ready : bool):
	$Label.add_color_override("font_color", Color(1.0,1.0,1.0) if is_ready else Color(0.6,0.6,0.6))

func get_username():
	return tr("general.unkown_username") if (player.username == "") else player.username

func update_display():
	$Label.text = get_username()
	_set_is_ready(player.ready)
	_update_faction_color()

func _update_faction_color():
	var style = get("custom_styles/panel")
	var duplicated_style = style.duplicate() if style != null else StyleBoxFlat.new()
	if player.faction != null and player.faction as int != 0:
		var color = Store._state.factions[player.faction as float].color
		duplicated_style.border_color =  Color(color[0] / 255.0, color[1] / 255.0, color[2] / 255.0,0.5)
	else:
		duplicated_style.border_color = Color(0.12,0.12,0.12,0.5)
	set("custom_styles/panel",duplicated_style)
