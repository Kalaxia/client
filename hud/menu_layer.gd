extends Control
class_name MenuLayer

signal menu_opened(menu_name)
signal menu_closed(menu_name)

const MENU_FLEET = preload("res://hud/system/fleet/menu_fleet.tscn")
const MENU_HANGAR = preload("res://hud/system/buildings/hangar.tscn")
const MENU_CONSTRUCTION = preload("res://hud/system/buildings/contruction/construction_menu.tscn")
const MENU_FINANCE = preload("res://hud/hud_menu/finance/finance_menu.tscn")
const MENU_OPTIONS = preload("res://hud/hud_menu/options/menu_option_hud.tscn")

var menus = {
	"menu_fleet" : MENU_FLEET.instance(),
	"menu_shipyard" : MENU_HANGAR.instance(),
	"menu_construction" : MENU_CONSTRUCTION.instance(),
	"menu_finance" : MENU_FINANCE.instance(),
	"menu_options" : MENU_OPTIONS.instance(),
}


func _ready():
	pass


func _notification(what):
	if what == NOTIFICATION_PREDELETE or what == NOTIFICATION_WM_QUIT_REQUEST:
		# destructor
		_delete_menues()


func request_menu(menu_requested):
	if get_all_menu_name().has(menu_requested):
		return
	close_menu()
	if menus.has(menu_requested):
		var menu = menus[menu_requested]
		add_child(menu)
		print_stack()
		menu.connect("close_requested", self, "close_menu", [menu_requested])
		menu.show_menu()
		menu.set_anchors_and_margins_preset(Control.PRESET_VCENTER_WIDE)
		print_stack()
		emit_signal("menu_opened", menu_requested)


func close_menu(menu_closed = ""):
	if get_child_count() == 0:
		return false
	if menu_closed == "":
		for node_index in range(get_child_count()):
			var node = get_child(node_index)
			var menu_closed_name = get_menu_name(node_index)
			_remove_menu(node)
			print_stack()
			emit_signal("menu_closed", menu_closed_name)
		return true
	elif menus.has(menu_closed):
		for node in get_children():
			if node == menus[menu_closed]:
				_remove_menu(node)
				print_stack()
				emit_signal("menu_closed", menu_closed)
				return true
	return false


func get_menu_name(position = 0):
	if get_child_count() <= position:
		return ""
	var node = get_child(position)
	for menu_key in menus.keys():
		if menus[menu_key] == node:
			return menu_key
	return "unkown"


func get_all_menu_name():
	var array_name = []
	for i in range(get_child_count()):
		array_name.push_back(get_menu_name(i))
	return array_name


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
	print_stack()
	node.disconnect("close_requested", self, "close_menu")
	remove_child(node) 
	# this does not queue_free the node.
	# make sure that ref to these element are stored somewhere


func _delete_menues():
	for node in menus.values():
		if node != null and is_instance_valid(node):
			# we have to free the menus otherwise we may leak memory
			node.queue_free()
