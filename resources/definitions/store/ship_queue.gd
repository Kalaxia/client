class_name ShipQueue
extends Squadron

signal finished()
signal canceled()

export(int) var finished_at
export(int) var started_at
export(int) var created_at
export(String) var assigned_fleet_id = null
export(String) var assgined_formation = null


func _init(dict = null).(dict):
	pass


func load_dict(dict) -> void:
	if dict == null:
		return
	.load_dict(dict)
	if dict is Dictionary and dict.has("assigned_fleet") and dict.assigned_fleet != null:
		# we do not want to load "assigned_fleet" from object as this prop does not exist
		# assigned_fleet : "fleet_id:formation"
		var assigned_fleet_array = dict.assigned_fleet.split(":")
		if assigned_fleet_array.size() == 2:
			assigned_fleet_id = assigned_fleet_array[0]
			assgined_formation = assigned_fleet_array[1]


func _get_dict_property_list():
	return ._get_dict_property_list() + ["finished_at", "started_at", "created_at", "assigned_fleet_id", "assgined_formation"]


func on_finished():
	emit_signal("finished")


func on_canceled():
	emit_signal("canceled")
