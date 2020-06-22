extends PanelContainer


export(Array,String) var option_list = [] setget set_option_list
export(int) var selected_item setget set_selected_item
export(bool) var disabled = false setget set_disabled

signal item_selected(item_id)

func _ready():
	$HBoxContainer/MenuButton.connect("item_selected",self,"_on_item_selected")


func set_option_list(new_option_list):
	option_list = new_option_list
	#todo

func _on_item_selected(item_id):
	emit_signal("item_selected",item_id)

func set_selected_item(item_id : int):
	if item_id < option_list.size():
		return
	
func set_disabled(is_disabled : bool):
	disabled = is_disabled
	$HBoxContainer/MenuButton.disabled = disabled
