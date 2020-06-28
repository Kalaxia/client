extends VBoxContainer

signal locale_updated()

var _locales = []

func _ready():
	_locales = TranslationServer.get_loaded_locales()
	_locales.sort()
	var selected_locale = 0
	for i in range(_locales.size()):
		var a = TranslationServer.get_locale()
		if _locales[i] == a:
			selected_locale = i
	$OptionArray.option_list = _locales
	$OptionArray.selected_item = selected_locale
	if _locales.size() < 2:
		$OptionArray.disabled = true
	$OptionArray.connect("item_selected",self,"_on_language_selected")

func _on_language_selected(item_id):
	if  item_id < 0 || item_id >= _locales.size():
		return
	# we do not set the local yet. We wait to quit the main menu
	# the reason is that we need to reload nodes to update the translations
	Config.set_config_locale(_locales[item_id])
