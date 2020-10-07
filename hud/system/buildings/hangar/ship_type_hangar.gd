extends Control

signal pressed()

var category setget set_category
var quantity = 0 setget set_quantity
var is_selected = false setget set_is_selected

onready var selectable_panel_container = $SelectablePanelContainer
onready var texture_ship = $SelectablePanelContainer/VBoxContainer/TextureRect
onready var label = $SelectablePanelContainer/VBoxContainer/MarginContainer/Label

const assets = preload("res://resources/assets.tres")


func _ready():
	selectable_panel_container.connect("pressed", self, "_on_pressed")
	update_quantity()
	update_texture()
	selectable_panel_container.is_selected = is_selected


func update_texture():
	if category != null and texture_ship != null:
		texture_ship.texture = assets.ship_models[category.category].texture


func _on_pressed():
	emit_signal("pressed")


func set_is_selected(selected):
	is_selected = selected
	if selectable_panel_container != null:
		selectable_panel_container.is_selected = is_selected


func update_quantity():
	if label != null:
		label.text = tr("hud.details.building.hangar.number_of_ship %d") % quantity


func set_category(new_category):
	if new_category == null:
		return
	category = new_category
	update_texture()


func set_quantity(new_quantity):
	quantity = max(0, new_quantity)
	update_quantity()
