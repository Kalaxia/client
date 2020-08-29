extends TabContainer


# this cannot be a constant as we want to reloads name if the local changes
onready var _tabs_name = [
	tr("hud.menu.finance.transfer"),
]


func _ready():
	_update_language_tabs() 


func _update_language_tabs():
	for i in range(get_tab_count()):
		set_tab_title(i, _tabs_name[i])
