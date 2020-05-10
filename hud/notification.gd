extends Panel

var notif = null
var timer = null

func _ready():
	get_node("Container/Title").set_text(notif.title)
	get_node("Container/Content").set_text(notif.content)
	var timer = $Timer
	timer.set_one_shot(true)
	timer.connect("timeout", self, "_on_timer_timeout") 
	timer.start(5)

func _on_timer_timeout():
	queue_free()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
