extends Node2D

const FLIGHT_TIME = 10 # in second
var time = 0
var origin_position = 0
var destination_position = 0
var color = null

func _ready():
	var curve = Curve2D.new()
	$FleetPath.curve = curve
	curve.add_point(origin_position)
	curve.add_point(destination_position)
	get_node("FleetPath/Follower/FleetIcon").set_modulate(Color(color[0], color[1], color[2]))

func _process(delta):
	time += delta
	get_node("FleetPath/Follower").unit_offset = time/FLIGHT_TIME
