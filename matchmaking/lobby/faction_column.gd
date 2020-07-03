extends VBoxContainer


const BANNERS = {
	"Kalankar": preload("res://resources/assets/2d/faction/kalankar/banner.png"),
	"Valkar": preload("res://resources/assets/2d/faction/valkar/banner.png"),
	"Adranite": preload("res://resources/assets/2d/faction/adranite/banner.png"),
}
const PLAYER_INFO_FACTION_COLUMN = preload("res://matchmaking/player/player_info_faction_column.tscn")

export(int) var faction = 0 setget set_faction

enum UPDATE_PLAYER_STATE {
	PLAYER_UPDATED,
	PLAYER_ADDED,
	PLAYER_REMOVED,
	PLAYER_IGNORED,
}

func _ready():
	_update_faction_banner()

func add_player(player):
	var node = PLAYER_INFO_FACTION_COLUMN.instance()
	node.player = player
	$ScrollContainer/VBoxContainer.add_child(node)
	return UPDATE_PLAYER_STATE.PLAYER_ADDED

func remove_player(player):
	for node in $ScrollContainer/VBoxContainer.get_children():
		if node is PlayerInfoFactionColumn and node.player.id == player.id:
			node.queue_free()
			return UPDATE_PLAYER_STATE.PLAYER_REMOVED
	return UPDATE_PLAYER_STATE.PLAYER_IGNORED

func update_player(player):
	if not _is_of_current_faction(player):
		return remove_player(player)
	for node in $ScrollContainer/VBoxContainer.get_children():
		if node is PlayerInfoFactionColumn && node.player.id == player.id:
			node.update_player(player)
			return UPDATE_PLAYER_STATE.PLAYER_UPDATED
	return add_player(player) 

func _is_of_current_faction(player):
	return ( player.faction == null and faction == 0 ) or ( player.faction != null and player.faction as int == faction )

func set_faction(new_faction):
	if ! Store._state.factions.has(new_faction as float) ||  new_faction as int == 0:
		return
	faction = new_faction as int
	_update_faction_banner()

func _update_faction_banner():
	var style = $ScrollContainer.get("custom_styles/bg")
	var duplicated_style = style.duplicate()
	if faction != 0:
		$Header/banner.visible = true
		$Header/banner.texture = BANNERS[Store._state.factions[faction as float].name]
		var color = Store._state.factions[faction as float].color
		duplicated_style.border_color =  Color(color[0] / 255.0, color[1] / 255.0, color[2] / 255.0)
	else:
		duplicated_style.border_color = Color(0.12,0.12,0.12)
		$Header/banner.visible = false
	$ScrollContainer.set("custom_styles/bg",duplicated_style)
