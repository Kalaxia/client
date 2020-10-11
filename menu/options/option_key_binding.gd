tool
class_name OptionKeyBinding
extends PanelContainer

signal mark_button_key_binding(action,index)
signal unmark_button_key_binding()

class ButtonKeyBinding:
	extends "res://gui/utils/button_click_sound_utils.gd"
	var index_key_binding

export(String) var action = "" setget set_action
export(bool) var is_enabled = false setget set_is_enabled

var index_pressed = -1

onready var container = $Container
onready var label = $Container/Label


func _ready():
	label.text = tr("action." + action)
	_refresh_data()
	if action != null and action != "":
		name = action


func set_is_enabled(new_value):
	is_enabled = new_value
	_update_enabled()


func _update_enabled():
	if container == null:
		return
	for node in container.get_children():
		if node is Button:
			node.disabled = not is_enabled


func set_action(new_value):
	action = new_value
	if label != null:
		label.text = tr("action." + action)
		_refresh_data()


func on_button_press(action_param, index_param):
	for node in container.get_children():
		if node is Button and (node.index_key_binding != index_param or action_param != action):
			node.pressed = false
	# we set the index to the correct one after deactivate the otehr button
	# as when it is toggled it will call _on_button_toggled and set index_pressed to -1
	index_pressed = index_param if (action_param == action) else -1


func _refresh_data():
	for node in container.get_children():
		if node is Button:
			node.queue_free()
	var keys = InputMap.get_action_list(action)
	for i in range(keys.size()):
		var button = ButtonKeyBinding.new()
		button.toggle_mode = true
		button.rect_min_size = Vector2(100,10)
		button.index_key_binding = i # todo find a better way
		button.disabled = not is_enabled
		button.connect("toggled", self, "_on_button_toggled", [i])
		var text_button = Utils.get_label_of_event(keys[i]) if not Engine.editor_hint else keys[i].to_string()
		if text_button != "":
			button.text = text_button
			container.add_child(button)


func _on_button_toggled(is_pressed,index):
	#note: this event ocure even when this is not a mouse event
	if is_pressed:
		emit_signal("mark_button_key_binding", action,index)
	else:
		index_pressed = -1


func _input(event):
	if index_pressed  == -1:
		return
	var previous_event = InputMap.get_action_list(action)[index_pressed]
	if (event is InputEventKey or event is InputEventMouseButton) and event.is_pressed() and not event.is_action("ui_forbbiden_key_rebind"):
		InputMap.action_erase_event(action,previous_event)
		InputMap.action_add_event(action,event)
		Config.set_key_binding(action)
		for node in container.get_children():
			if node is Button:
				node.pressed = false
		index_pressed = -1
		get_tree().set_input_as_handled()
		emit_signal("unmark_button_key_binding")
		_refresh_data()
