extends Control

signal scene_requested(scene)

const KEY_BINDING_OPTION = preload("res://menu/options/option_key_binding.tscn")
const AUDIO_VOLUME = preload("res://menu/options/audio_volume_control.tscn")

# this cannot be a constant as we want to reloads name if the local changes
onready var _tabs_name = [
	tr("menu.option.tab.shortcuts"),
	tr("menu.option.tab.audio"),
	tr("menu.option.tab.graphical"),
	tr("menu.option.tab.lang"),
]
onready var key_binding_container = $TabContainer/Raccourcis/ScrollContainer/keyBindingContainer
onready var tab_container = $TabContainer
onready var main_menu_button = $ButtonsContainer/MainMenu
onready var audio_container = $TabContainer/Audio/AudioScrollContainer/AudioContainer


func _ready():
	_update_language_tabs()
	for node in key_binding_container.get_children():
			if node is OptionKeyBinding:
				node.connect("mark_button_key_binding", self, "_on_mark_button_key_binding")
				node.connect("unmark_button_key_binding", self, "_on_unmark_button_key_binding")
				node.is_enabled = Config.ENABLE_KEY_BINDING_CHANGE.has(node.action)
	main_menu_button.connect("pressed", self, "_on_back_to_main_menu")
	for index_bus in range(AudioServer.bus_count):
		var node = AUDIO_VOLUME.instance()
		node.bus_id = index_bus
		audio_container.add_child(node)


func _update_language_tabs():
	for i in range(tab_container.get_tab_count()):
		tab_container.set_tab_title(i, _tabs_name[i])


func _on_mark_button_key_binding(action, index):
	for i in key_binding_container.get_children():
		if i is OptionKeyBinding:
			i.on_button_press(action, index)


func _on_unmark_button_key_binding():
	pass


func _on_back_to_main_menu():
	Config.save_config_file()
	Config.reload_locale()
	emit_signal("scene_requested", "menu")
