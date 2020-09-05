extends PanelContainer

var notif = null

onready var timer = $Timer


func _ready():
	get_node("Container/Title").set_text(notif.title)
	get_node("Container/Content").set_text(notif.content)
	timer.set_one_shot(true)
	timer.connect("timeout", self, "_on_timer_timeout") 
	timer.start(5)
	$AnimationPlayer.current_animation = "fade_in"


func _on_timer_timeout():
	$AnimationPlayer.play_backwards()
	$AnimationPlayer.connect("animation_finished",self,"_on_animation_finished")
	


func _on_animation_finished(_animation_name):
	queue_free()
