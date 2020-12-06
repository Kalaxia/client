extends CheckButton

onready var animation = $AnimationPlayer

func _ready():
	pass


func too_much_animation():
	animation.play("too_much")
