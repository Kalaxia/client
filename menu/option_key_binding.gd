extends Control

class_name OptionKeyBinding

var action = "" setget set_action
var is_enabled = false setget set_is_enabled
var index_pressed = -1

signal mark_button_key_binding(action,index)
signal unmark_button_key_binding()

class ButtonKeyBinding:
	extends Button
	var index_key_binding

func _ready():
	$Label.text = tr("action." + action)
	_refresh_data()

func _refresh_data():
	for node in get_children():
		if node is Button:
			node.queue_free()
	var keys = InputMap.get_action_list(action)
	for i in range(keys.size()):
		var button = ButtonKeyBinding.new()
		button.toggle_mode = true
		button.rect_min_size = Vector2(100,10)
		button.index_key_binding = i # todo find a better way
		button.disabled = ! is_enabled
		button.connect("toggled",self,"_on_button_toggled",[i])
		var text_button = Utils.get_label_of_event(keys[i])
		if text_button != "":
			button.text = text_button
			add_child(button)

func on_button_press(action_param,index_param):
	for node in get_children():
		if node is Button && (node.index_key_binding != index_param || action_param != action):
			node.pressed = false
	# we set the index to the correct one after deactivate the otehr button
	# as when it is toggled it will call _on_button_toggled and set index_pressed to -1
	index_pressed = index_param if (action_param == action) else -1

func _on_button_toggled(is_pressed,index):
	#note: this event ocure even when this is not a mouse event
	if is_pressed:
		emit_signal("mark_button_key_binding",action,index)
	else:
		index_pressed = -1

func _input(event):
	if index_pressed  == -1:
		return
	var previous_event = InputMap.get_action_list(action)[index_pressed]
	if (event is InputEventKey || (event is InputEventMouseButton && event.get_button_index() != BUTTON_LEFT)) && event.is_pressed():
		InputMap.action_erase_event(action,previous_event)
		InputMap.action_add_event(action,event)
		Config.save_key_binding(action)
		for node in get_children():
			if node is Button:
				node.pressed = false
		index_pressed = -1
		emit_signal("unmark_button_key_binging")
		_refresh_data()

func set_is_enabled(new_value):
	is_enabled = new_value
	for node in get_children():
		if node is Button:
			node.disabled = ! is_enabled

func set_action(new_value):
	action = new_value
	$Label.text = tr("action." + action)
	_refresh_data()
