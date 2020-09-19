class_name ShipQueue
extends ShipGroup

signal finished()
signal canceled()

export(int) var finished_at
export(int) var started_at
export(int) var created_at


func _init(dict = null).(dict):
	pass


func load_dict(dict) -> void:
	if dict == null:
		return
	.load_dict(dict)


func _get_dict_property_list():
	return ._get_dict_property_list() + ["finished_at", "started_at", "created_at"]


func on_finished():
	emit_signal("finished")


func on_canceled():
	emit_signal("canceled")
