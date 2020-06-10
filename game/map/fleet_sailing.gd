extends Node2D

const FLIGHT_TIME = 10.0 # in second
var _time = 0.0
var origin_position = Vector2.ZERO
var destination_position = Vector2.ZERO
var color = null
var fleet = null


func _ready():
	var curve = Curve2D.new()
	$FleetPath.curve = curve
	curve.add_point(origin_position)
	curve.add_point(destination_position)
	get_node("FleetPath/Follower/SpritesContainer").set_modulate(color)
	var vector_trajectori = destination_position - origin_position
	get_node("FleetPath/Follower/SpritesContainer/FleetIcon").rotate(-vector_trajectori.angle_to(Vector2.RIGHT))
	get_node("FleetPath/Follower/SpritesContainer/Crown").visible = (fleet.player == Store._state.player.id)
	if fleet.player == Store._state.player.id:
		get_node("FleetPath/Follower/SpritesContainer").set_scale(Vector2(0.75,0.75))
	_set_icone_texture()

func _process(delta):
	_time += delta
	get_node("FleetPath/Follower").unit_offset = _time/FLIGHT_TIME

func _set_icone_texture():
	$FleetPath/Follower/SpritesContainer/FleetIcon.faction = Store.get_game_player(fleet.player).faction
	$FleetPath/Follower/SpritesContainer/FleetIcon.set_faction_texture()
