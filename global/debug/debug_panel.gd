extends Node

const BUTTON_POSITION = Vector2(30, 30)
const DISTANCE_SHOW = 80

var is_mouse_close_to_top_left = false

onready var button_container_animation = $Layer/ButtonContainer/AnimationPlayer
onready var button = $Layer/ButtonContainer/Button
onready var menu_header = $Layer/MenuContainer/MenuHeader
onready var menu_container = $Layer/MenuContainer
onready var button_debug_frame = $Layer/MenuContainer/MenuBody/Body/MarginContainer/VBoxContainer/CheckBox

func _ready():
	button.connect("pressed", self, "_on_pressed")
	menu_header.connect("close_request", self , "_on_close_request")
	menu_container.visible = false
	_update_debug_frame_buton()
	Config.config_environment.connect("show_debug_frame_changed", self, "_on_show_debug_frame_changed")
	button_debug_frame.connect("pressed", self, "_on_button_debug_frame_pressed")


func _input(event):
	if event is InputEventMouseMotion:
		var button_center_pos = button.rect_size / 2.0 + BUTTON_POSITION
		var relative_dist = (event.position - button_center_pos).length()
		if relative_dist <= DISTANCE_SHOW and not is_mouse_close_to_top_left:
			button_container_animation.play("move_debug_button")
			is_mouse_close_to_top_left = true
		elif is_mouse_close_to_top_left and relative_dist > DISTANCE_SHOW:
			button_container_animation.play_backwards("move_debug_button")
			is_mouse_close_to_top_left = false


func _on_pressed():
	menu_container.visible = button.pressed


func _on_close_request():
	menu_container.visible = false
	button.pressed = false


func _on_show_debug_frame_changed():
	_update_debug_frame_buton()


func _update_debug_frame_buton():
	button_debug_frame.pressed = Config.config_environment.show_debug_frame


func _on_button_debug_frame_pressed():
	Config.config_environment.show_debug_frame = button_debug_frame.pressed
