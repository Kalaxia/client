tool
class_name MenuBody, "res://resources/editor/menu_body.svg"
extends PanelContainer

var _warning_string = ""

func _ready():
	if Engine.editor_hint:
		if get_child_count() == 0:
			var node = VBoxContainer.new()
			node.name = "Body"
			add_child(node)
			node.set_owner(get_tree().edited_scene_root)
		queue_sort()


func _notification(what):
	if what == NOTIFICATION_SORT_CHILDREN:
		post_sort_children()


func post_sort_children():
	_reset_warning()
	if get_child_count() != 1:
		_warn("Expecting 1 children")
	for node in get_children():
		node.size_flags_vertical = SIZE_EXPAND_FILL


func _reset_warning():
	_warning_string = ""
	update_configuration_warning()


func _warn(string):
	# editor only : show a warning on the container node
	_warning_string += ("\n" if _warning_string != "" else "") + string
	update_configuration_warning()


func _get_configuration_warning():
	# editor only : override see node._get_configuration_warning()
	return _warning_string


func minimize_toogle():
	visible = not visible
