extends Control

const _TEXTURE_SYSTEM = {
	"VictorySystem":{
		0 : preload("res://resources/assets/2d/map/picto_syteme.png"),
		1 : preload("res://resources/assets/2d/map/kalankar/picto_syteme_masque_v2-01.png"),
		2 : preload("res://resources/assets/2d/map/valkar/picto_syteme_serpent_v2-01.png"),
		3 : preload("res://resources/assets/2d/map/adranite/picto_syteme_epee_v2-01.png"),
	},
	"BaseSystem"  : {
		0 : preload("res://resources/assets/2d/map/picto_syteme_1_neutral.png"),
		1 : preload("res://resources/assets/2d/map/kalankar/picto_syteme_masque-01.png"),
		2 : preload("res://resources/assets/2d/map/valkar/picto_syteme_serpent-01.png"),
		3 : preload("res://resources/assets/2d/map/adranite/picto_systeme_epee-01.png"),
	},
}

var fleet_details_scene = preload("res://hud/system/system_fleet_details.tscn")
var building_details_scene = preload("res://hud/system/system_building_details.tscn")


func _ready():
	Store.connect("system_selected", self, "_on_system_selected")
	Store.connect("system_update", self, "_on_system_update")
	Network.connect("Victory", self, "_on_victory")
	set_visible(false)
	var fleet_details = fleet_details_scene.instance()
	$MenuSystem.add_child(fleet_details)
	$System/Container/ButtonContainer/ButtonBuilding.connect("pressed",self,"_on_building_pressed")
	$System/Container/ButtonContainer/ButtonFleet.connect("pressed",self,"_on_fleet_pressed")

func _on_system_selected(system, old_system):
	set_visible(true)
	refresh_data(system)

func refresh_data(system):
	var player_node = $System/Container/ContainerSystem/PlayerName
	var player = null
	if system.player != null:
		player = Store.get_game_player(system.player)
		player_node.text = player.username
	else:
		player_node.text = ""
	$System/Container/ContainerSystem/TextureRect.texture = _TEXTURE_SYSTEM[system.kind][0 if player == null else player.faction as int]
	$System/Container/ContainerSystem/TextureRect.modulate = Store.get_player_color(player, system.kind == "VictorySystem")

func _on_victory(data):
	set_visible(false)

func _on_system_update(system):
	if system.id == Store._state.selected_system.id:
		refresh_data(Store._state.selected_system)

func _input(event):
	pass
	# todo
	
func _on_building_pressed():
	for node in $MenuSystem.get_children():
		node.queue_free()
	if $System/Container/ButtonContainer/ButtonBuilding.pressed:
		$System/Container/ButtonContainer/ButtonFleet.pressed = false
		$MenuSystem.add_child(building_details_scene.instance())
		

func _on_fleet_pressed():
	for node in $MenuSystem.get_children():
		node.queue_free()
	if $System/Container/ButtonContainer/ButtonFleet.pressed:
		$System/Container/ButtonContainer/ButtonBuilding.pressed = false
		$MenuSystem.add_child(fleet_details_scene.instance())


