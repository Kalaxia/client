extends Control

var key_binding_option = preload("res://menu/option_key_binding.tscn")

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const ENABLE_KEY_BINDING_CHANGE = [
	"ui_zoom_out_map",
	"ui_zoom_in_map",
	"ui_drag_map",
	"ui_move_map_up",
	"ui_move_map_down",
	"ui_move_map_left",
	"ui_move_map_right",
	"ui_add_fleet",
	"ui_add_ships",
]

signal scene_requested(scene)

# Called when the node enters the scene tree for the first time.
func _ready():
	var actions = InputMap.get_actions()
	for i in actions:
		var node_key = key_binding_option.instance()
		node_key.set_name(i)
		node_key.action = i
		node_key.connect("mark_button_key_binding",self,"_on_mark_button_key_binding")
		for allowed_actions in ENABLE_KEY_BINDING_CHANGE:
			if i == allowed_actions :
				node_key.is_enable = true
		$CenterContainer/VBoxContainer/ScrollContainer/keyBingingContainer.add_child(node_key)
		$CenterContainer/VBoxContainer/Button.connect("pressed",self,"_on_back_to_main_menu")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_mark_button_key_binding(action,index):
	for i in $CenterContainer/VBoxContainer/ScrollContainer/keyBingingContainer.get_children():
		if i is OptionKeyBinding:
			i.on_button_press(action,index)
func _on_back_to_main_menu():
	emit_signal("scene_requested","menu")
