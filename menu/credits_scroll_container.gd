extends Control

const SPEED = 50.0

onready var node_position = $VBoxContainer
onready var rich_text_label = $VBoxContainer/RichTextLabel


func _ready():
	rich_text_label.bbcode_text = tr("menu.credits.main")
	_set_position_credits_bottom()
	for _i in range(2):
		yield(get_tree(), "idle_frame")
	# for some reason I need to wait 2 frames before we get the correct rect_size.y
	# but we need to set the credits position on the bottom
	# I test wating for the ready of MenuCredits but it does not work
	_set_position_credits_bottom()


func _process(delta):
	node_position.rect_position += Vector2.UP  * delta * SPEED
	if node_position.rect_position.y < - node_position.rect_size.y:
		_set_position_credits_bottom()


func _set_position_credits_bottom():
	node_position.rect_position = Vector2(0.0, rect_size.y)
