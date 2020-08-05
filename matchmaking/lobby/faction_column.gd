extends VBoxContainer

const assets = preload("res://resources/assets.tres")
const PLAYER_INFO_FACTION_COLUMN = preload("res://matchmaking/player/player_info_faction_column.tscn")

export(int) var faction = 0 setget set_faction

enum UPDATE_PLAYER_STATE {
	PLAYER_UPDATED,
	PLAYER_ADDED,
	PLAYER_REMOVED,
	PLAYER_IGNORED,
}

onready var container = $ScrollContainer/VBoxContainer
onready var scroll_container = $ScrollContainer
onready var header_banner = $Header/banner


func _ready():
	_update_faction_banner()


func add_player(player):
	var node = PLAYER_INFO_FACTION_COLUMN.instance()
	node.player = player
	container.add_child(node)
	return UPDATE_PLAYER_STATE.PLAYER_ADDED


func remove_player(player):
	for node in container.get_children():
		if node is PlayerInfoFactionColumn and node.player.id == player.id:
			node.queue_free()
			return UPDATE_PLAYER_STATE.PLAYER_REMOVED
	return UPDATE_PLAYER_STATE.PLAYER_IGNORED


func update_player(player):
	if not _is_of_current_faction(player):
		return remove_player(player)
	for node in container.get_children():
		if node is PlayerInfoFactionColumn and node.player.id == player.id:
			node.update_player(player)
			return UPDATE_PLAYER_STATE.PLAYER_UPDATED
	return add_player(player) 


func _is_of_current_faction(player):
	return ( player.faction == null and faction == 0 ) or ( player.faction != null and player.faction as int == faction )


func set_faction(new_faction):
	if not Store._state.factions.has(new_faction as float) or  new_faction as int == 0:
		return
	faction = new_faction as int
	_update_faction_banner()


func _update_faction_banner():
	if scroll_container == null:
		return
	var style = scroll_container.get("custom_styles/bg")
	var duplicated_style = style.duplicate()
	if faction != 0:
		header_banner.visible = true
		header_banner.texture = assets.factions[faction].banner
		var color = assets.factions[faction].get_color()
		duplicated_style.border_color =  Color(color[0] / 255.0, color[1] / 255.0, color[2] / 255.0)
	else:
		duplicated_style.border_color = Color(0.12,0.12,0.12)
		header_banner.visible = false
	scroll_container.set("custom_styles/bg",duplicated_style)
