extends VBoxContainer

var _locales = []

export(bool) var enabled = true setget set_enabled

onready var option_array = $OptionArray

func _ready():
	_locales = TranslationServer.get_loaded_locales()
	_locales.sort()
	var selected_locale = 0
	for i in range(_locales.size()):
		var a = TranslationServer.get_locale()
		if _locales[i] == a:
			selected_locale = i
	option_array.option_list = _locales
	option_array.selected_item = selected_locale
	if _locales.size() < 2:
		option_array.disabled = true
	option_array.connect("item_selected", self, "_on_language_selected")
	_update_element()


func set_enabled(new_bool):
	enabled = new_bool
	_update_element()


func _update_element():
	option_array.disabled = not enabled


func _on_language_selected(item_id):
	if  item_id < 0 or item_id >= _locales.size():
		return
	# we do not set the local yet. We wait to quit the main menu
	# the reason is that we need to reload nodes to update the translations
	Config.set_config_locale(_locales[item_id])
