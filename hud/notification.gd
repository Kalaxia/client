extends PanelContainer

const TIME_DISPALYED = 5.0 # in seconds

var notif = null

onready var timer = $Timer
onready var animation_player = $AnimationPlayer



func _ready():
	get_node("Container/Title").set_text(notif.title)
	get_node("Container/Content").set_text(notif.content)
	timer.set_one_shot(true)
	timer.connect("timeout", self, "_on_timer_timeout") 
	timer.start(TIME_DISPALYED)
	animation_player.current_animation = "fade_in"


func _on_timer_timeout():
	animation_player.play_backwards()
	animation_player.connect("animation_finished", self, "_on_animation_finished")


func _on_animation_finished(_animation_name):
	queue_free()
