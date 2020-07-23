extends Control

signal closed()

onready var menu_header = $MenuHeader


func _ready():
	menu_header.connect("close_request", self, "_on_close_request")


func _on_close_request():
	emit_signal("closed")
	queue_free()
