class_name State
extends Reference

signal state_exited()
signal state_entered()

var fsm = null
var is_active = false setget private_set

# handleing input
func _input(event : FSMEvent) -> void:
	pass


# called when entering the state (virtual function)
func _entering():
	pass


# called when leaving the state (virtual function)
func _leaving():
	pass


func _enter():
	_entering()
	is_active = true
	emit_signal("state_entered")


func _leave():
	_leaving()
	is_active = false
	emit_signal("state_exited")


# function used to switch to a certain state 
func switch_to(st : State) -> void:
	_leave()
	fsm.set_current_state(st)
	st._enter()


func private_set(variant):
	pass
