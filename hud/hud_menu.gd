extends VBoxContainer

const assets = preload("res://resources/assets.tres")

signal back_main_menu() 

var _game_data = Store.game_data
var menu_layer : MenuLayer setget set_menu_layer

onready var texture_rect = $HBoxContainer/TextureRect
onready var button_container_left = $HBoxContainer/ButtonContainerLeft
onready var button_container_right = $HBoxContainer/ButtonContainerRight
onready var menu_button = $HBoxContainer/ButtonContainerRight/SelectablePanelContainerMenu
onready var popup_menu = $HBoxContainer/ButtonContainerRight/SelectablePanelContainerMenu/PopupMenu
onready var finance_button = $HBoxContainer/ButtonContainerRight/SelectablePanelContainerFinance
onready var combat_button = $HBoxContainer/ButtonContainerRight/CombatReport


func _ready():
	var button_array = button_container_left.get_children() + button_container_right.get_children()
	for node in button_array:
		if node is SelectablePanelContainer:
			node.connect("pressed", self, "_on_button_pressed", [node])
	menu_button.connect("state_changed", self, "_toogle_menu")
	popup_menu.connect("id_pressed", self, "_on_id_pressed")
	texture_rect.texture = _game_data.player.faction.banner
	finance_button.connect("pressed", self, "_on_finance_menu_pressed")
	combat_button.connect("pressed", self, "_on_combat_button_pressed")


func set_menu_layer(node):
	if menu_layer != null and menu_layer.is_connected("menu_closed", self, "_on_menu_layer_menu_closed"):
		menu_layer.disconnect("menu_closed", self, "_on_menu_layer_menu_closed")
	menu_layer = node
	menu_layer.connect("menu_closed", self, "_on_menu_layer_menu_closed")


func update_theme():
	var button_array = button_container_left.get_children() + button_container_right.get_children()
	for node_list in button_array:
		if node_list is SelectablePanelContainer:
			node_list.update_style()


func _on_button_pressed(node):
	deselect_other_node(node)


func deselect_other_node(node = null):
	var button_array = button_container_left.get_children() + button_container_right.get_children()
	for node_list in button_array:
		if node != null and node_list is SelectablePanelContainer and node_list.get_path() != node.get_path():
			node_list.is_selected = false


func _back_to_main_menu():
	_game_data.request_leave_game()
	emit_signal("back_main_menu")


func _toogle_menu(is_pressed):
	popup_menu.visible = is_pressed
	if is_pressed:
		# is it possible to find a better way to do that ?
		popup_menu.rect_global_position = menu_button.rect_global_position + Vector2(2.0, 2.0 + menu_button.rect_size.y) 


func _on_id_pressed(id):
	Audio.play_click()
	match id:
		0:
			menu_layer.request_menu("menu_options")
		2:
			_back_to_main_menu()
	menu_button.is_selected = false


func _on_finance_menu_pressed():
	if finance_button.is_selected:
		menu_layer.request_menu("menu_finance")
	else:
		menu_layer.close_menu("menu_finance")


func _on_menu_layer_menu_closed(menu_name):
	if menu_name == "menu_finance":
		finance_button.is_selected = false
	elif menu_name == "menu_combat_report":
		combat_button.is_selected = false


func _on_combat_button_pressed():
	if combat_button.is_selected:
		menu_layer.request_menu("menu_combat_report")
	else:
		menu_layer.close_menu("menu_combat_report")
