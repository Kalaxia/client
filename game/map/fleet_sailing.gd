extends Node2D

const FLIGHT_TIME = 10.0 # in second
var _time = 0.0
var origin_position = Vector2.ZERO
var destination_position = Vector2.ZERO
var color = null
var fleet = null

const _TEXTURE_CROWN_FACTION_1= preload("res://resources/assets/2d/map/crown_fleet_faction_1.png")
const _TEXTURE_CROWN_FACTION_2= preload("res://resources/assets/2d/map/crown_fleet_faction_2.png")
const _TEXTURE_CROWN_FACTION_3= preload("res://resources/assets/2d/map/crown_fleet_faction_3.png")


func _ready():
	var curve = Curve2D.new()
	$FleetPath.curve = curve
	curve.add_point(origin_position)
	curve.add_point(destination_position)
	get_node("FleetPath/Follower/SpritesContainer").set_modulate(color)
	var vector_trajectori = destination_position - origin_position
	get_node("FleetPath/Follower/SpritesContainer/FleetIcon").rotate(-vector_trajectori.angle_to(Vector2.RIGHT))
	if fleet.player == Store._state.player.id:
		get_node("FleetPath/Follower/SpritesContainer").set_scale(Vector2(0.75,0.75))
	_set_icone_texture()
	_set_crown_state()

func _process(delta):
	_time += delta
	get_node("FleetPath/Follower").unit_offset = _time/FLIGHT_TIME

func _set_icone_texture():
	$FleetPath/Follower/SpritesContainer/FleetIcon.faction = Store.get_game_player(fleet.player).faction
	$FleetPath/Follower/SpritesContainer/FleetIcon.set_faction_texture()

func _set_crown_state():
	var is_current_player = (fleet.player == Store._state.player.id)
	get_node("FleetPath/Follower/SpritesContainer/Crown").visible = is_current_player
	if is_current_player:
		match Store.get_game_player(fleet.player).faction as int:
			1:
				$FleetPath/Follower/SpritesContainer/Crown.texture = _TEXTURE_CROWN_FACTION_1
			2:
				$FleetPath/Follower/SpritesContainer/Crown.texture = _TEXTURE_CROWN_FACTION_2
			3:
				$FleetPath/Follower/SpritesContainer/Crown.texture = _TEXTURE_CROWN_FACTION_3
			_:
				$FleetPath/Follower/SpritesContainer/Crown.texture = _TEXTURE_CROWN_FACTION_1
	
