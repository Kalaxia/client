extends Node2D

const _SCALE_CURRENT_PLAYER_FACTOR = 1.0
const BASE_SCALE = 0.75

var origin_position = Vector2.ZERO
var destination_position = Vector2.ZERO
var fleet : Fleet = null setget set_fleet
var _game_data : GameData = Store.game_data

onready var sprite_container = $FleetPath/Follower/SpritesContainer
onready var sprite_crown = $FleetPath/Follower/SpritesContainer/CrownSprite
onready var fleet_sprite = $FleetPath/Follower/SpritesContainer/FleetIcon
onready var _time_departure = OS.get_system_time_msecs()


func _ready():
	var curve = Curve2D.new()
	curve.add_point(origin_position)
	curve.add_point(destination_position)
	$FleetPath.curve = curve
	var color = _game_data.get_player_color(_game_data.get_player(fleet.player))
	sprite_container.set_modulate(color)
	_set_size_sprite()
	_set_icone_texture()
	_set_crown_state()


func _process(_delta):
	$FleetPath/Follower.unit_offset = _get_flight_ratio()


func set_fleet(new_fleet):
	fleet = new_fleet
	_set_size_sprite()


func _set_size_sprite():
	if fleet != null and sprite_container != null:
		var scale_sprite = _SCALE_CURRENT_PLAYER_FACTOR if _game_data.does_belong_to_current_player(fleet) else 1.0
		sprite_container.scale = Vector2(BASE_SCALE * scale_sprite, BASE_SCALE * scale_sprite)


func _get_flight_time_ms():
	# it is possible that fleet.destination_arrival_date is set to null before this objet is freed (because of queue_free) can call _process
	return (fleet.destination_arrival_date - _time_departure) if fleet.destination_arrival_date != null else 0


func _get_flight_ratio():
	return ((OS.get_system_time_msecs () - _time_departure) as float / _get_flight_time_ms() as float) if _get_flight_time_ms() != 0 else 1.0


func _set_icone_texture():
	fleet_sprite.faction = _game_data.get_player(fleet.player).faction


func _set_crown_state():
	var is_current_player = (fleet.player == _game_data.player.id)
	sprite_crown.visible = is_current_player
	if is_current_player:
		sprite_crown.faction = _game_data.get_player(fleet.player).faction
