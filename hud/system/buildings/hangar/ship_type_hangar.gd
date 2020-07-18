extends Control

var model setget set_model
var quantity = 0 setget set_quantity

var is_selected = false setget set_is_selected

signal pressed()

func _ready():
	$SelectablePanelContainer.connect("pressed", self, "_on_pressed")
	update_quantity()
	update_texture()

func update_texture():
	if model != null:
		$SelectablePanelContainer/VBoxContainer/TextureRect.texture = Utils.TEXTURE_SHIP_MODEL[model]

func _on_pressed():
	emit_signal("pressed")

func set_is_selected(selected):
	is_selected = selected
	$SelectablePanelContainer.is_selected = is_selected


func update_quantity():
	$SelectablePanelContainer/VBoxContainer/MarginContainer/Label.text = quantity as String

func set_model(new_model):
	if not Utils.SHIP_MODEL.has(new_model) and new_model != null:
		return
	model = new_model
	update_texture()

func set_quantity(new_quantity):
	quantity = max(0, new_quantity)
	update_quantity()
