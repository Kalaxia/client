extends PanelContainer


export(Array,String) var option_list = [] setget set_option_list
export(int) var selected_item setget set_selected_item
export(bool) var disabled = false setget set_disabled
export(String) var text setget set_text

signal item_selected(item_id)

func _ready():
	$HBoxContainer/OptionButton.connect("item_selected",self,"_on_item_selected")


func set_option_list(new_option_list):
	$HBoxContainer/OptionButton.clear()
	option_list = new_option_list
	for i in option_list:
		$HBoxContainer/OptionButton.add_item(i)
	if selected_item >= option_list.size() || selected_item < 0:
		selected_item =0
	$HBoxContainer/OptionButton.select(selected_item)

func _on_item_selected(item_id):
	emit_signal("item_selected",item_id)

func set_selected_item(item_id : int):
	if item_id >= option_list.size() || item_id < 0 :
		return
	selected_item = item_id
	$HBoxContainer/OptionButton.select(selected_item)
	
func set_disabled(is_disabled : bool):
	disabled = is_disabled
	$HBoxContainer/MenuButton.disabled = disabled

func set_text(new_text: String):
	text = new_text
	$HBoxContainer/label.text = tr(new_text)
