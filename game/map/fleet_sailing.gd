extends Node2D

var origin_position = Vector2.ZERO
var destination_position = Vector2.ZERO
var color = null
var fleet = null
var arrival_time
onready var _time_departure = OS.get_unix_time()

const _SCALE_CURRENT_PLAYER_FACTOR = 1.0

const _TEXTURE_CROWN = {
	1 : preload("res://resources/assets/2d/map/kalankar/couronne.png"),
	2 : preload("res://resources/assets/2d/map/valkar/couronne.png"),
	3 : preload("res://resources/assets/2d/map/adranite/couronne.png"),
}

func _ready():
	var curve = Curve2D.new()
	$FleetPath.curve = curve
	curve.add_point(origin_position)
	curve.add_point(destination_position)
	get_node("FleetPath/Follower/SpritesContainer").set_modulate(color)
	#var vector_trajectori = destination_position - origin_position
	#get_node("FleetPath/Follower/SpritesContainer/FleetIcon").rotate(-vector_trajectori.angle_to(Vector2.RIGHT))
	if fleet.player == Store._state.player.id:
		get_node("FleetPath/Follower/SpritesContainer").set_scale(Vector2(0.5 * _SCALE_CURRENT_PLAYER_FACTOR ,0.5 * _SCALE_CURRENT_PLAYER_FACTOR))
	_set_icone_texture()
	_set_crown_state()

func _process(delta):
	get_node("FleetPath/Follower").unit_offset = _get_flight_ratio()

func _get_flight_time_ms():
	return (arrival_time - _time_departure)

func _get_flight_ratio():
	return (OS.get_unix_time() - _time_departure) / _get_flight_time_ms()

func _set_icone_texture():
	$FleetPath/Follower/SpritesContainer/FleetIcon.faction = Store.get_game_player(fleet.player).faction
	$FleetPath/Follower/SpritesContainer/FleetIcon.set_faction_texture()
	

func _set_crown_state():
	var is_current_player = (fleet.player == Store._state.player.id)
	get_node("FleetPath/Follower/SpritesContainer/CrownSprite").visible = is_current_player
	if is_current_player:
		$FleetPath/Follower/SpritesContainer/CrownSprite.faction = Store.get_game_player(fleet.player).faction
		$FleetPath/Follower/SpritesContainer/CrownSprite.set_faction_texture()
	
