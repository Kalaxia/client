extends Control

const KEY_BINDING_OPTION = preload("res://menu/options/option_key_binding.tscn")
const AUDIO_VOLUME = preload("res://menu/options/audio_volume_control.tscn")

export(bool) var language_enabled = true setget set_language_enabled
export(bool) var audio_enabled = true setget set_audio_enabled
export(bool) var graphical_enabled = true setget set_graphical_enabled
export(bool) var shortcut_enabled = true setget set_shortcut_enabled

# this cannot be a constant as we want to reloads name if the local changes
onready var _tabs_name = [
	tr("menu.option.tab.shortcuts"),
	tr("menu.option.tab.audio"),
	tr("menu.option.tab.graphical"),
	tr("menu.option.tab.lang"),
]
onready var key_binding_container = $TabContainer/Raccourcis/ScrollContainer/keyBindingContainer
onready var tab_container = $TabContainer
onready var audio_container = $TabContainer/Audio/AudioScrollContainer/AudioContainer
onready var option_langauge_container = $TabContainer/language/ScrollContainer/OptionLang
onready var graphical_option = $TabContainer/Graphics/GraphicsScrollContainer2/GraphicsOption


func _ready():
	_update_language_tabs()
	for node in key_binding_container.get_children():
			if node is OptionKeyBinding:
				node.connect("mark_button_key_binding", self, "_on_mark_button_key_binding")
				node.connect("unmark_button_key_binding", self, "_on_unmark_button_key_binding")
				node.is_enabled = Config.ENABLE_KEY_BINDING_CHANGE.has(node.action) and shortcut_enabled
	for index_bus in range(AudioServer.bus_count):
		var node = AUDIO_VOLUME.instance()
		node.bus_id = index_bus
		node.disabled = not audio_enabled
		audio_container.add_child(node)
	_update_language_enabled()
	_update_graphical_option_enabled()


func set_shortcut_enabled(new_bool):
	shortcut_enabled = new_bool
	_updated_shortcut_enabled()


func _updated_shortcut_enabled():
	if key_binding_container:
		for node in key_binding_container.get_children():
			if node is OptionKeyBinding:
				node.is_enabled = Config.ENABLE_KEY_BINDING_CHANGE.has(node.action) and shortcut_enabled


func set_language_enabled(new_bool):
	language_enabled = new_bool
	_update_language_enabled()


func _update_language_enabled():
	if option_langauge_container:
		option_langauge_container.enabled = language_enabled


func set_graphical_enabled(new_bool):
	graphical_enabled = new_bool
	_update_graphical_option_enabled()


func _update_graphical_option_enabled():
	if graphical_option:
		graphical_option.enabled = graphical_enabled


func set_audio_enabled(new_bool):
	audio_enabled = new_bool
	_update_volume_enabled()


func _update_volume_enabled():
	if audio_container == null:
		return
	for node in audio_container:
		if node is VolumeOption:
			node.disabled = not audio_enabled


func _update_language_tabs():
	for i in range(tab_container.get_tab_count()):
		tab_container.set_tab_title(i, _tabs_name[i])


func _on_mark_button_key_binding(action, index):
	for i in key_binding_container.get_children():
		if i is OptionKeyBinding:
			i.on_button_press(action, index)


func _on_unmark_button_key_binding():
	pass
