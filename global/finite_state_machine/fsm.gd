class_name FSM
extends Reference

signal state_changing(state)

var current_state = null setget private_set


func set_current_state(state):
	current_state = state
	emit_signal("state_changing", state)


func input(input : FSMEvent):
	current_state._input(input)


func private_set(variant):
	pass

