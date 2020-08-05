extends Node2D

var origin_position = Vector2.ZERO
var destination_position = Vector2.ZERO
var color = null
var fleet = null
var arrival_time
onready var _time_departure = OS.get_system_time_msecs()

const _SCALE_CURRENT_PLAYER_FACTOR = 1.0

const assets = preload("res://resources/assets.tres")

func _ready():
	var curve = Curve2D.new()
	$FleetPath.curve = curve
	curve.add_point(origin_position)
	curve.add_point(destination_position)
	$FleetPath/Follower/SpritesContainer.set_modulate(color)
	#var vector_trajectori = destination_position - origin_position
	#get_node("FleetPath/Follower/SpritesContainer/FleetIcon").rotate(-vector_trajectori.angle_to(Vector2.RIGHT))
	if fleet.player == Store._state.player.id:
		$FleetPath/Follower/SpritesContainer.set_scale(Vector2(0.5 * _SCALE_CURRENT_PLAYER_FACTOR ,0.5 * _SCALE_CURRENT_PLAYER_FACTOR))
	_set_icone_texture()
	_set_crown_state()

func _process(delta):
	$FleetPath/Follower.unit_offset = _get_flight_ratio()

func _get_flight_time_ms():
	return (arrival_time - _time_departure)

func _get_flight_ratio():
	return ((OS.get_system_time_msecs () - _time_departure) as float / _get_flight_time_ms() as float) if _get_flight_time_ms() != 0 else 1.0

func _set_icone_texture():
	$FleetPath/Follower/SpritesContainer/FleetIcon.faction = Store.get_game_player(fleet.player).faction
	

func _set_crown_state():
	var is_current_player = (fleet.player == Store._state.player.id)
	var sprite = $FleetPath/Follower/SpritesContainer/CrownSprite
	sprite.visible = is_current_player
	if is_current_player:
		sprite.faction = Store.get_game_player(fleet.player).faction
