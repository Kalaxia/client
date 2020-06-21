extends Control

var key_binding_option = preload("res://menu/option_key_binding.tscn")
var audio_volume = preload("res://menu/audio_volume_control.tscn")


signal scene_requested(scene)

func _ready():
	var actions = InputMap.get_actions()
	actions.sort()
	for i in actions:
		var node_key = key_binding_option.instance()
		node_key.set_name(i)
		node_key.action = i
		node_key.connect("mark_button_key_binding",self,"_on_mark_button_key_binding")
		node_key.connect("unmark_button_key_binding",self,"_on_unmark_button_key_binding")
		for allowed_actions in Config.ENABLE_KEY_BINDING_CHANGE:
			if i == allowed_actions :
				node_key.is_enabled = true
		$TabContainer/Raccourcis/ScrollContainer/keyBindingContainer.add_child(node_key)
	$ButtonsContainer/MainMenu.connect("pressed",self,"_on_back_to_main_menu")
	var continue_looking_for_audio_bus = true
	var index_bus = 0
	while continue_looking_for_audio_bus:
		var name_bus = AudioServer.get_bus_name(index_bus)
		if index_bus > 20 || name_bus == "" || name_bus == null:
			continue_looking_for_audio_bus = false
		else:
			var node = audio_volume.instance()
			node.bus_id = index_bus
			$TabContainer/Audio/AudioScrollContainer/AudioContainer.add_child(node)
			index_bus += 1

func _on_mark_button_key_binding(action,index):
	#$CenterContainer/VBoxContainer/ScrollContainer.mouse_filter(MOUSE_FILTER_IGNORE)
	for i in $TabContainer/Raccourcis/ScrollContainer/keyBindingContainer.get_children():
		if i is OptionKeyBinding:
			i.on_button_press(action,index)

func _on_unmark_button_key_binding():
	#$CenterContainer/VBoxContainer/ScrollContainer.mouse_filter(MOUSE_FILTER_STOP)
	pass

func _on_back_to_main_menu():
	emit_signal("scene_requested","menu")
