extends Control

signal pressed()

var category setget set_category
var quantity = 0 setget set_quantity
var is_selected = false setget set_is_selected

const assets = preload("res://resources/assets.tres")

func _ready():
	$SelectablePanelContainer.connect("pressed", self, "_on_pressed")
	update_quantity()
	update_texture()


func update_texture():
	if category != null:
		$SelectablePanelContainer/VBoxContainer/TextureRect.texture = assets.ship[category.category]


func _on_pressed():
	emit_signal("pressed")


func set_is_selected(selected):
	is_selected = selected
	$SelectablePanelContainer.is_selected = is_selected


func update_quantity():
	$SelectablePanelContainer/VBoxContainer/MarginContainer/Label.text = tr("hud.details.building.hangar.number_of_ship %d") % quantity


func set_category(new_category):
	if new_category == null:
		return
	category = new_category
	update_texture()


func set_quantity(new_quantity):
	quantity = max(0, new_quantity)
	update_quantity()
