class_name SelectedState
extends Resource

signal system_selected(old_system)
signal system_unselected(old_system)
signal fleet_selected(old_fleet)
signal fleet_unselected(old_fleet)
# fleets
signal fleet_owner_updated()
signal fleet_update_nb_ships()
signal fleet_updated()
# arrived is not connected because a moving fleet should not be selected
# system
signal fleet_added(fleet)
signal fleet_erased(fleet)
signal building_updated()
signal building_contructed(building)
signal hangar_updated(hangar)
signal system_owner_updated()
signal system_updated()
signal system_fleet_arrived(fleet)
signal system_fleet_owner_updated(fleet)
signal ship_queue_finished(ship_group)
signal ship_queue_added(ship_queue)
signal ship_queue_removed(ship_queue)
signal conquerred()

export(Resource) var selected_system = null setget select_system
export(Resource) var selected_fleet = null setget select_fleet


func _ready():
	# verify if it is needed
	_connect_system(selected_system)
	_connect_fleet(selected_fleet)


func select_system(system : System):
	if system == selected_system:
		return
	var old_system = selected_system
	_disconnect_system(old_system)
	selected_system = system
	_connect_system(selected_system)
	emit_signal("changed")
	if selected_system:
		emit_signal("system_selected", old_system)
	else:
		emit_signal("system_unselected", old_system)


func unselect_system():
	select_system(null)


func select_fleet(fleet : Fleet):
	if fleet == selected_fleet:
		return
	var old_fleet = selected_fleet
	_disconnect_fleet(old_fleet)
	selected_fleet = fleet
	_connect_fleet(selected_fleet)
	emit_signal("changed")
	if selected_fleet:
		emit_signal("fleet_selected", old_fleet)
	else:
		emit_signal("fleet_unselected", old_fleet)


func unselect_fleet():
	select_fleet(null)


func is_selected_system(system : System):
	return system.id == selected_system.id


func _disconnect_fleet(fleet : Fleet):
	if fleet == null:
		return
	if fleet.is_connected("owner_updated", self, "_on_fleet_owner_updated"):
		fleet.disconnect("owner_updated", self, "_on_fleet_owner_updated")
	if fleet.is_connected("fleet_update_nb_ships", self, "_on_fleet_update_nb_ships"):
		fleet.disconnect("fleet_update_nb_ships", self, "_on_fleet_update_nb_ships")
	if fleet.is_connected("updated", self, "_on_fleet_updated"):
		fleet.disconnect("updated", self, "_on_fleet_updated")


func _connect_fleet(fleet : Fleet):
	if fleet == null:
		return
	if not fleet.is_connected("owner_updated", self, "_on_fleet_owner_updated"):
		fleet.connect("owner_updated", self, "_on_fleet_owner_updated")
	if not fleet.is_connected("fleet_update_nb_ships", self, "_on_fleet_update_nb_ships"):
		fleet.connect("fleet_update_nb_ships", self, "_on_fleet_update_nb_ships")
	if not fleet.is_connected("updated", self, "_on_fleet_updated"):
		fleet.connect("updated", self, "_on_fleet_updated")


func _on_fleet_updated():
	emit_signal("fleet_updated")


func _on_fleet_owner_updated():
	emit_signal("fleet_owner_updated")


func _on_fleet_update_nb_ships():
	emit_signal("fleet_update_nb_ships")


func _disconnect_system(system : System):
	if system == null:
		return
	if system.is_connected("fleet_added", self, "_on_fleet_added"):
		system.disconnect("fleet_added", self, "_on_fleet_added")
	if system.is_connected("fleet_erased", self, "_on_fleet_erased"):
		system.disconnect("fleet_erased", self, "_on_fleet_erased")
	if system.is_connected("building_updated", self, "_on_building_updated"):
		system.disconnect("building_updated", self, "_on_building_updated")
	if system.is_connected("hangar_updated", self, "_on_hangar_updated"):
		system.disconnect("hangar_updated", self, "_on_hangar_updated")
	if system.is_connected("system_owner_updated", self, "_on_system_owner_updated"):
		system.disconnect("system_owner_updated", self, "_on_system_owner_updated")
	if system.is_connected("updated", self, "_on_system_updated"):
		system.disconnect("updated", self, "_on_system_updated")
	if system.is_connected("fleet_arrived", self, "_on_fleet_arrived"):
		system.disconnect("fleet_arrived", self, "_on_fleet_arrived")
	if system.is_connected("fleet_owner_updated", self, "_on_system_fleet_owner_updated"):
		system.disconnect("fleet_owner_updated", self, "_on_system_fleet_owner_updated")
	if system.is_connected("ship_queue_finished", self, "_on_ship_queue_finished"):
		system.disconnect("ship_queue_finished", self, "_on_ship_queue_finished")
	if system.is_connected("ship_queue_added", self, "_on_ship_queue_added"):
		system.disconnect("ship_queue_added", self, "_on_ship_queue_added")
	if system.is_connected("ship_queue_removed", self, "_on_ship_queue_removed"):
		system.disconnect("ship_queue_removed", self, "_on_ship_queue_removed")
	if system.is_connected("building_contructed", self, "_on_building_contructed"):
		system.disconnect("building_contructed", self, "_on_building_contructed")
	if system.is_connected("conquerred", self, "_on_conquerred"):
		system.disconnect("conquerred", self, "_on_conquerred")


func _connect_system(system : System):
	if system == null:
		return
	if not system.is_connected("fleet_added", self, "_on_fleet_added"):
		system.connect("fleet_added", self, "_on_fleet_added")
	if not system.is_connected("fleet_erased", self, "_on_fleet_erased"):
		system.connect("fleet_erased", self, "_on_fleet_erased")
	if not system.is_connected("building_updated", self, "_on_building_updated"):
		system.connect("building_updated", self, "_on_building_updated")
	if not system.is_connected("hangar_updated", self, "_on_hangar_updated"):
		system.connect("hangar_updated", self, "_on_hangar_updated")
	if not system.is_connected("system_owner_updated", self, "_on_system_owner_updated"):
		system.connect("system_owner_updated", self, "_on_system_owner_updated")
	if not system.is_connected("updated", self, "_on_system_updated"):
		system.connect("updated", self, "_on_system_updated")
	if not system.is_connected("fleet_arrived", self, "_on_fleet_arrived"):
		system.connect("fleet_arrived", self, "_on_fleet_arrived")
	if not system.is_connected("fleet_owner_updated", self, "_on_system_fleet_owner_updated"):
		system.connect("fleet_owner_updated", self, "_on_system_fleet_owner_updated")
	if not system.is_connected("ship_queue_finished", self, "_on_ship_queue_finished"):
		system.connect("ship_queue_finished", self, "_on_ship_queue_finished")
	if not system.is_connected("ship_queue_added", self, "_on_ship_queue_added"):
		system.connect("ship_queue_added", self, "_on_ship_queue_added")
	if not system.is_connected("ship_queue_removed", self, "_on_ship_queue_removed"):
		system.connect("ship_queue_removed", self, "_on_ship_queue_removed")
	if not system.is_connected("building_contructed", self, "_on_building_contructed"):
		system.connect("building_contructed", self, "_on_building_contructed")
	if not system.is_connected("conquerred", self, "_on_conquerred"):
		system.connect("conquerred", self, "_on_conquerred")


func _on_conquerred():
	emit_signal("conquerred")


func _on_building_contructed(building):
	emit_signal("building_contructed", building)


func _on_system_fleet_owner_updated(fleet):
	emit_signal("system_fleet_owner_updated", fleet)


func _on_ship_queue_removed(ship_queue):
	emit_signal("ship_queue_removed", ship_queue)


func _on_ship_queue_added(ship_queue):
	emit_signal("ship_queue_added", ship_queue)


func _on_ship_queue_finished(ship_group):
	emit_signal("ship_queue_finished", ship_group)


func _on_fleet_arrived(fleet):
	emit_signal("system_fleet_arrived", fleet)


func _on_system_updated():
	emit_signal("system_updated")


func _on_system_owner_updated():
	emit_signal("system_owner_updated")


func _on_fleet_added(fleet):
	emit_signal("fleet_added", fleet)


func _on_fleet_erased(fleet):
	emit_signal("fleet_erased", fleet)


func _on_building_updated():
	emit_signal("building_updated")


func _on_hangar_updated(hangar):
	emit_signal("hangar_updated", hangar)
