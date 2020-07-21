extends PanelContainer

signal item_selected(item_id)

export(Array,String) var option_list = [] setget set_option_list
export(int) var selected_item setget set_selected_item
export(bool) var disabled = false setget set_disabled
export(String) var text = "" setget set_text

onready var option_button = $HBoxContainer/OptionButton
onready var label = $HBoxContainer/label


func _ready():
	option_button.connect("item_selected",self,"_on_item_selected")
	label.text = tr(text)


func set_option_list(new_option_list):
	option_button.clear()
	option_list = new_option_list
	for i in option_list:
		option_button.add_item(i)
	if selected_item >= option_list.size() || selected_item < 0:
		selected_item =0
	option_button.select(selected_item)


func _on_item_selected(item_id):
	emit_signal("item_selected",item_id)


func set_selected_item(item_id : int):
	if item_id >= option_list.size() || item_id < 0 :
		return
	selected_item = item_id
	option_button.select(selected_item)


func set_disabled(is_disabled : bool):
	disabled = is_disabled
	option_button.disabled = disabled


func set_text(new_text: String):
	text = new_text
	if label != null:
		label.text = tr(text)
