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
	get_node("FleetPath/Follower/FleetIcon").set_modulate(color)
	if fleet.player == Store._state.player.id:
		get_node("FleetPath/Follower/FleetIcon").set_scale(Vector2(0.75,0.75))

func _process(delta):
	_time += delta
	get_node("FleetPath/Follower").unit_offset = _time/FLIGHT_TIME
