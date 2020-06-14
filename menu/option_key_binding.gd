extends Control

class_name OptionKeyBinding

var action = ""
var is_enable = false
var index_pressed = -1

signal mark_button_key_binding(action,index)


# Called when the node enters the scene tree for the first time.
func _ready():
	$Label.text = action
	_refresh_data()

func _refresh_data():
	for node in get_children():
		if node is Button:
			node.queue_free()
	var keys = InputMap.get_action_list(action)
	for i in range(keys.size()):
		var button = Button.new()
		button.toggle_mode = true
		button.rect_min_size = Vector2(100,10)
		button.editor_description = i as String # todo find a better way
		button.disabled = ! is_enable
		button.connect("toggled",self,"_on_button_toggled",[i])
		if keys[i] is InputEventKey:
			button.text = keys[i].as_text()
			add_child(button)
		elif keys[i] is InputEventMouseButton:
			button.text =  "mouse_key_" + (keys[i].button_index as String)
			add_child(button)

func on_button_press(action_param,index_param):
	if action_param != action:
		index_pressed = -1
	else:
		index_pressed = index_param
	for node in get_children():
		if node is Button:
			if node.editor_description != index_param as String || action_param != action:
				node.pressed = false

func _on_button_toggled(state,index):
	if state:
		emit_signal("mark_button_key_binding",action,index)
	else:
		index_pressed = -1

func _input(event):
	if index_pressed  != -1:
		var previous_event = InputMap.get_action_list(action)[index_pressed]
		if (event is InputEventKey || (event is InputEventMouseButton && event.get_button_index() != BUTTON_LEFT)) && event.is_pressed():
			InputMap.action_erase_event(action,previous_event)
			InputMap.action_add_event(action,event)
			for node in get_children():
				if node is Button:
					node.pressed = false
			index_pressed = -1
			_refresh_data()
