extends VBoxContainer

signal back_main_menu() 

onready var texture_rect = $HBoxContainer/TextureRect
onready var button_container_left = $HBoxContainer/ButtonContainerLeft
onready var button_container_right = $HBoxContainer/ButtonContainerRight
onready var menu_button = $HBoxContainer/ButtonContainerRight/SelectablePanelContainerMenu
onready var popup_menu = $HBoxContainer/ButtonContainerRight/SelectablePanelContainerMenu/PopupMenu


func _ready():
	var button_array = button_container_left.get_children() + button_container_right.get_children()
	for node in button_array:
		if node is SelectablePanelContainer:
			node.connect("pressed", self, "_on_button_pressed", [node])
	menu_button.connect("state_changed", self, "_toogle_menu")
	popup_menu.connect("id_pressed", self, "_on_id_pressed")
	texture_rect.texture = Utils.BANNERS[Store._state.player.faction as int]


func update_theme(game = null):
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
	Store.request_leave_game()
	emit_signal("back_main_menu")


func _toogle_menu(is_pressed):
	popup_menu.visible = is_pressed
	if is_pressed:
		# is it possible to find a better way to do that ?
		popup_menu.rect_global_position = menu_button.rect_global_position + Vector2(2.0, 2.0 + menu_button.rect_size.y) 


func _on_id_pressed(id):
	match id:
		0:
			_back_to_main_menu()
