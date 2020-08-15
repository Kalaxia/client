extends Node2D

const KEY_BINDING_LABEL = preload("res://gui/key_binding_label/key_binding_label.tscn")

export(String) var action = "" setget set_action
export(int) var max_number_of_label = 1 setget set_max_number_of_label
export(PoolStringArray) var override_label_text = [] setget set_override_label_text
export(PoolIntArray) var pos_of_events = [] setget set_pos_of_events
export(bool) var visibility = true setget set_visibility, get_visibility

var _label_array = []

onready var container = $HBoxContainer


func _ready():
	# todo add visibility toggle
	_remove_nodes()
	if action == "":
		_add_nodes(max_number_of_label)
	else:
		_add_nodes()


func set_visibility(visibility_param):
	#todo review
	visibility = visibility_param
	.set_visible(visibility)


func get_visibility():
	return self.visible


func set_action(new_action):
	if new_action == null or new_action == "":
		_remove_nodes()
		action = ""
		_updates_elements()
		_add_nodes(max_number_of_label)
		return
	if not InputMap.has_action(new_action):
		return
	_remove_nodes()
	action = new_action
	_updates_elements()
	_add_nodes()


func set_max_number_of_label(new_max):
	if new_max < 0 or new_max == max_number_of_label:
		return
	if new_max < max_number_of_label:
		_remove_nodes(max_number_of_label - new_max)
	else:
		_add_nodes(new_max - max_number_of_label)
	max_number_of_label = new_max


func set_override_label_text(new_labels):
	if new_labels is PoolStringArray:
		override_label_text = new_labels
	elif new_labels is String:
		override_label_text = PoolStringArray([new_labels])
	elif new_labels is Array:
		override_label_text = PoolStringArray(new_labels)
	else:
		return
	_updates_elements()


func set_pos_of_events(new_pos_of_events):
	if new_pos_of_events is PoolIntArray:
		pos_of_events = new_pos_of_events
	elif new_pos_of_events is int:
		pos_of_events = PoolIntArray([new_pos_of_events])
	elif new_pos_of_events is Array:
		pos_of_events = PoolIntArray(new_pos_of_events)
	else:
		return
	_updates_elements()


func _updates_elements():
	for i in range(_label_array.size()):
		var node = _label_array[i]
		_update_node(node, i)


func _update_node(node, index):
	var pos_event = index
	if index < pos_of_events.size() and pos_of_events[index] != null:
		pos_event = pos_of_events[index]
	node.event_pos = pos_event
	if index < override_label_text.size() and override_label_text[index] != null:
		node.override_label_text = override_label_text[index]


func _remove_nodes(number_of_node = max_number_of_label):
	var counter = 0
	while counter < number_of_node and _label_array.size() > 0:
		var node = _label_array.pop_back()
		node.queue_free()
		counter += 1


func _add_nodes(number_of_node = _get_number_of_events()):
	if container == null:
		return
	var number_of_event_already = _label_array.size()
	var number_of_node_added = clamp(min(number_of_node, _get_number_of_events() - number_of_event_already), 0, max(max_number_of_label - number_of_event_already, 0))
	for i in range(number_of_event_already, number_of_node_added + number_of_event_already):
		var node = KEY_BINDING_LABEL.instance()
		node.action = action
		_update_node(node, i)
		_label_array.push_back(node)
		container.add_child(node)


func _get_number_of_events():
	return _get_event_list().size()


func _get_event_list():
	return InputMap.get_action_list(action) if action != "" and InputMap.has_action(action) else []
