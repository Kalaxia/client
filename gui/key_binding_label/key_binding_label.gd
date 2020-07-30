extends MarginContainer

export(String) var action = "" setget set_action
export(int) var event_pos = 0 setget set_event_pos
export(String) var override_label_text = null setget set_override_label_text

onready var label = $PanelContainer/Label


func _ready():
	_set_label()


func set_action(new_action):
	if new_action == "" or new_action == null:
		action = ""
		_set_label()
		return
	if not InputMap.has_action(new_action):
		return
	action = new_action
	if event_pos >= InputMap.get_action_list(action).size():
		event_pos = 0
	_set_label()


func set_event_pos(new_pos):
	if action == null or action == "" or not InputMap.has_action(action) or new_pos < 0 or new_pos >= InputMap.get_action_list(action).size():
		return
	event_pos = new_pos
	_set_label()


func set_override_label_text(new_label):
	override_label_text = new_label
	_set_label()


func _set_label():
	if label != null:
		label.text = _get_label_text()


func _get_label_text():
	if override_label_text != "" and override_label_text != null:
		return   override_label_text
	var event = _get_event()
	return Utils.get_label_of_event(event) if event != null else ""


func _get_event():
	if action == null or action == "" or not InputMap.has_action(action):
		return null
	var action_list = InputMap.get_action_list(action)
	var pos_used = event_pos if event_pos < action_list.size() else 0
	return action_list[pos_used]
