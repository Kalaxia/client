extends Node2D

const FLIGHT_TIME = 10.1 # in second
var time = 0

func _ready():
	pass # Replace with function body.

func _process(delta):
	time += delta
	get_node("FleetPath/Follower").unit_offset = time/FLIGHT_TIME
