extends VBoxContainer

const ASSETS = preload("res://resources/assets.tres")
const PLAYER_INFO_FACTION_COLUMN = preload("res://matchmaking/player/player_info_faction_column.tscn")

export(int) var faction = 0 setget set_faction # resource ?

enum UPDATE_PLAYER_STATE {
	PLAYER_UPDATED,
	PLAYER_ADDED,
	PLAYER_REMOVED,
	PLAYER_IGNORED,
}

onready var container = $ScrollContainer/VBoxContainer
onready var scroll_container = $ScrollContainer
onready var header_banner = $Header/banner
onready var label_faction = $Header/Label


func _ready():
	_update_faction_banner()


func add_player(player):
	for node in container.get_children():
		if node is PlayerInfoFactionColumn and node.player.id == player.id:
			return UPDATE_PLAYER_STATE.PLAYER_IGNORED
	# in the case where the player is not there
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
	return ( player.faction == null and faction == 0 ) or ( player.faction != null and player.faction.id as int == faction )


func set_faction(new_faction):
	new_faction = new_faction as int
	if new_faction < 1 or new_faction >= ASSETS.factions.size():
		return
	faction = new_faction
	_update_faction_banner()


func _update_faction_banner():
	if scroll_container == null:
		return
	var style = scroll_container.get("custom_styles/bg")
	if faction != 0:
		header_banner.visible = true
		header_banner.texture = ASSETS.factions[faction].banner
		style.border_color = ASSETS.factions[faction].get_color()
		label_faction.text = ASSETS.factions[faction].display_name
	else:
		style.border_color = Color(0.12,0.12,0.12)
		header_banner.visible = false
		label_faction.text = ""
	scroll_container.set("custom_styles/bg", style)
