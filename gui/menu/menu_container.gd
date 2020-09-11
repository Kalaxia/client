tool
class_name MenuContainer, "res://resources/editor/menu_container.svg"
extends VBoxContainer

signal close_requested()
signal minimize_toogled(visible_state)

const MENU_HEADER = preload("res://gui/menu/menu_header.tscn")

var menu_header
var menu_body
var _warning_string = "" # for the editor warning system, has no effect outside the editor


func _init():
	set("custom_constants/separation", 0)


func _ready():
	var has_menu_header = false
	var has_menu_body = false
	for node in get_children():
		if node is MenuHeader:
			menu_header = node
			has_menu_header = true
			menu_header.connect("close_request", self, "close_request")
			menu_header.connect("minimize_request", self, "minimize_toogle")
		elif node is MenuBody:
			has_menu_body = true
			menu_body = node
	if Engine.editor_hint:
		if not has_menu_header:
			menu_header = MENU_HEADER.instance()
			menu_header.name = "MenuHeader"
			add_child(menu_header)
		if not has_menu_body:
			menu_body = MenuBody.new()
			menu_body.name = "MenuBody"
			add_child(menu_body)
		menu_header.set_owner(get_tree().edited_scene_root)
		menu_body.set_owner(get_tree().edited_scene_root)
		queue_sort()


func _enter_tree():
	show_menu()


func _notification(what):
	if what == NOTIFICATION_SORT_CHILDREN:
		post_sort_children()


func post_sort_children():
	_reset_warning()
	if get_child_count() != 2:
		_warn("Expecting 2 children : one MenuHeader, one MenuBody")
	var has_menu_header = false
	var has_menu_body = false
	for node in get_children():
		if node is MenuHeader:
			move_child(node, 0)
			has_menu_header = true
		elif node is MenuBody:
			has_menu_body = true
			node.size_flags_vertical = SIZE_EXPAND_FILL
			node.show_behind_parent = true
	if not has_menu_header:
		_warn("There is no MenuHeader")
	if not has_menu_body:
		_warn("There is no MenuBody")


func _reset_warning():
	_warning_string = ""
	update_configuration_warning()


func _warn(string):
	# editor only : show a warning on the container node
	_warning_string += ("\n" if _warning_string != "" else "") + string
	update_configuration_warning()


func _get_configuration_warning():
	# editor only : override see node._get_configuration_warning()
	# todo review
	return _warning_string


func close_request():
	emit_signal("close_requested")


func minimize_toogle():
	if menu_body != null:
		menu_body.minimize_toogle()
		emit_signal("minimize_toogled", menu_body.visible)


func show_menu():
	if menu_body != null and not menu_body.visible:
		minimize_toogle()
