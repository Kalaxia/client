extends Control
class_name MenuLayer

const MENU_FLEET = preload("res://hud/system/fleet/menu_fleet.tscn")
const MENU_HANGAR = preload("res://hud/system/buildings/hangar.tscn")
const MENU_CONSTRUCTION = preload("res://hud/system/buildings/contruction/construction_menu.tscn")

var menus = {
	"menu_fleet" : MENU_FLEET.instance(),
	"menu_shipyard" : MENU_HANGAR.instance(),
	"menu_construction" : MENU_CONSTRUCTION.instance(),
}


func _ready():
	pass


func request_menu(menu_requested):
	close_menu()
	if menus.has(menu_requested):
		var menu = menus[menu_requested]
		add_child(menu)
		menu.connect("close_requested", self, "close_menu", [menu_requested])
		menu.show_menu()
		menu.set_anchors_and_margins_preset(Control.PRESET_VCENTER_WIDE)


func close_menu(menu_closed = ""):
	if get_child_count() == 0:
		return false
	if menu_closed == "":
		for node in get_children():
			_remove_menu(node)
		return true
	elif menus.has(menu_closed):
		for node in get_children():
			if node.get_path() == menus[menu_closed].get_path():
				_remove_menu(node)
				return true
	return false


func toogle_menu(menu_toogled):
	if menus.has(menu_toogled):
		var has_closed = close_menu(menu_toogled)
		if not has_closed:
			request_menu(menu_toogled)
		return not has_closed
	return null


func get_menu(menu):
	if menus.has(menu):
		return menus[menu]
	return null


func _remove_menu(node):
	node.disconnect("close_requested", self, "close_menu")
	remove_child(node) 
	# this does not queue_free the node.
	# make sure that ref to these element are stored somewhere
