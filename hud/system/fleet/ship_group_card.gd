class_name ShipGroupCard
extends PanelContainer #SelectablePanelContainer

export(Resource) var ship_group = null setget set_ship_group
export(String) var formation_position setget set_formation_position # string ?

var number_in_hangar = 0 setget set_number_in_hangar

onready var texture_rect = $MarginContainer/VBoxContainer/TextureRect
onready var category_label = $MarginContainer/VBoxContainer/LabelCategory
onready var spin_box = $MarginContainer/VBoxContainer/ShipNumber/HBoxContainerNumber/SpinBox
onready var label_max_number = $MarginContainer/VBoxContainer/ShipNumber/HBoxContainerNumber/PanelContainer/LabelMaxNumber
onready var progress_container = $MarginContainer/VBoxContainer/ProgressBar
onready var progress_bar =  $MarginContainer/VBoxContainer/ProgressBar/ProgressBar
onready var time_remaining_label = $MarginContainer/VBoxContainer/ProgressBar/LabelTime
onready var label_contructing_number = $MarginContainer/VBoxContainer/ProgressBar/LabelNumber
onready var button_add = $MarginContainer/VBoxContainer/ShipNumber/HBoxContainer/Button
onready var label_formation = $MarginContainer/VBoxContainer/LabelFormation


func _ready():
	button_add.connect("pressed", self, "_on_pressed_add")
	update_element()
	update_formation_position()


func _process(_delta):
	if ship_group == null or not ship_group is ShipQueue:
		set_process(false)
		return
	_update_time()


func _update_time():
	if time_remaining_label == null or progress_bar == null or not ship_group is ShipQueue:
		return
	var time_remaining = ship_group.ship_group - OS.get_system_time_msecs()
	time_remaining_label.text = tr("hud.system.fleet.menu.card.time %d") % floor(max(time_remaining, 0) / 1000.0 )
	var total_time =  (ship_group.finished_at - ship_group.started_at ) as float
	progress_bar.value = (1.0 - time_remaining as float/ total_time) if total_time != 0 else 1


func update_element():
	if texture_rect == null:
		return
	if ship_group == null:
		texture_rect.texture = null
		category_label.text = ""
		spin_box.value = ship_group.quantity
		spin_box.editable = false
		label_max_number.text = "0"
	else:
		texture_rect.texture = ship_group.category.texture
		category_label.text = ship_group.category.category
		spin_box.text = ship_group.quantity # todo keep ?
		spin_box.editable = true
		update_max_number()
		if ship_group is ShipQueue:
			progress_container.visible = true
			set_process(true)
			label_contructing_number.text = tr("hud.system.fleet.menu.card.number %d") % ship_group.quantity
		else:
			progress_container = false
			set_process(false)


func set_ship_group(new_ship_group):
	if not new_ship_group is ShipGroup and new_ship_group != null:
		return
	ship_group = new_ship_group
	update_element()


func set_number_in_hangar(new_number):
	number_in_hangar = new_number
	update_max_number()


func update_max_number():
	if label_max_number == null:
		return
	var quantity = ship_group.quantity if ship_group != null else 0
	label_max_number.text = (number_in_hangar + quantity ) as String
	spin_box.max_value = number_in_hangar + quantity


func set_formation_position(new_string):
	formation_position = new_string
	update_formation_position()


func update_formation_position():
	label_formation.text = formation_position


func _on_pressed_add():
	# todo
	pass
