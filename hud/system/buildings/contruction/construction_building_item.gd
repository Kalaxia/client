extends Control

export(String) var building_type = "" setget set_building_type

onready var texture_rect = $PanelContainer/HBoxContainer/TextureRect
onready var label = $PanelContainer/HBoxContainer/Label
onready var button = $PanelContainer/HBoxContainer/Button


func _ready():
	_updates_elements()
	button.connect("pressed", self, "_on_build_button")


func set_building_type(new_type):
	if not Utils.BUILDING_LIST.has(new_type):
		return
	building_type = new_type
	_updates_elements()


func _updates_elements():
	texture_rect.texture = Utils.TEXTURE_BUILDING[building_type]
	label.text = tr("hud.details.buidlng." + building_type) if building_type != "" else tr("hud.details.buidlng.contruction")


func _on_build_button():
	# request
	pass


func _on_building_construction_started():
	# call back
	pass
