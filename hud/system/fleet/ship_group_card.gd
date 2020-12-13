class_name ShipGroupCard
extends SelectablePanelContainer

export(Resource) var ship_group = null setget set_ship_group
export(String, "center", "left", "right", "rear") var formation_position setget set_formation_position # string ?
export(Array, Resource) var ship_queues_array setget set_ship_queues_array

var number_in_hangar = 0 setget set_number_in_hangar
var _game_data : GameData = Store.game_data

onready var texture_rect = $MarginContainer/VBoxContainer/TextureRect
onready var category_label = $MarginContainer/VBoxContainer/LabelCategory
onready var progress_container = $MarginContainer/VBoxContainer/ProgressBar
onready var progress_bar =  $MarginContainer/VBoxContainer/ProgressBar/ProgressBar
onready var time_remaining_label = $MarginContainer/VBoxContainer/ProgressBar/LabelTime
onready var label_contructing_number = $MarginContainer/VBoxContainer/ProgressBar/LabelNumber
onready var label_formation = $MarginContainer/VBoxContainer/LabelFormation
onready var label_max_number = $MarginContainer/VBoxContainer/ShipNumber/HBoxContainerNumber/PanelContainer/LabelMaxNumber


func _ready():
	update_element()
	update_formation_position()
	update_queue_process()


func _process(_delta):
	if ship_queues_array.size() == 0:
		progress_container.visible = false
		set_process(false)
		return
	_update_time()


func _update_time():
	if time_remaining_label == null or progress_bar == null:
		return
	var current_time = OS.get_system_time_msecs()
	var min_time = current_time
	var max_time = current_time
	for queue in ship_queues_array:
		# there is presicion problem when converting to float, use int function instead
		min_time = Utils.int_min(min_time, queue.started_at)
		max_time =  Utils.int_max(max_time, queue.finished_at)
	var time_remaining = max_time - current_time
	time_remaining_label.text = tr("hud.system.fleet.menu.card.time %d") % floor(max(time_remaining, 0.0) / 1000.0)
	var total_time =  (max_time - min_time) as float
	progress_bar.value = (1.0 - time_remaining as float / total_time) if total_time != 0.0 else 1.0


func update_element():
	if texture_rect == null:
		return
	if ship_group == null:
		texture_rect.texture = null
		category_label.text = ""
		label_max_number.text = "0"
	else:
		texture_rect.texture = ship_group.category.texture
		category_label.text = ship_group.category.category
		update_max_number()


func set_ship_queues_array(new_ship_queue_array):
	if ship_queues_array == new_ship_queue_array or new_ship_queue_array == null:
		return
	for queue in ship_queues_array:
		print_stack()
		queue.disconnect("finished", self, "_on_ship_queue_finished")
		queue.disconnect("canceled", self, "_on_ship_queue_canceled")
	# do not forget to duplicate
	ship_queues_array = new_ship_queue_array.duplicate(false)
	for queue in ship_queues_array:
		print_stack()
		queue.connect("finished", self, "_on_ship_queue_finished", [queue], CONNECT_ONESHOT)
		queue.connect("canceled", self, "_on_ship_queue_canceled", [queue], CONNECT_ONESHOT)
	update_queue_process()


func add_ship_queue(ship_queue):
	print_stack()
	ship_queue.connect("finished", self, "_on_ship_queue_finished", [ship_queue], CONNECT_ONESHOT)
	ship_queue.connect("canceled", self, "_on_ship_queue_canceled", [ship_queue], CONNECT_ONESHOT)
	ship_queues_array.push_back(ship_queue)
	update_queue_process()


func _on_ship_queue_finished(ship_queue):
	ship_queues_array.erase(ship_queue)
	update_queue_process()


func _on_ship_queue_canceled(ship_queue):
	ship_queues_array.erase(ship_queue)
	update_queue_process()


func update_queue_process():
	if ship_queues_array.size() > 0:
		progress_container.visible = true
		var quantity = 0
		for queue in ship_queues_array:
			quantity += queue.quantity
		label_contructing_number.text = tr("hud.system.fleet.menu.card.number %d") % quantity
		set_process(true)
	else:
		progress_container.visible = false
		set_process(false)


func set_ship_group(new_ship_group):
	if not new_ship_group is FleetSquadron and new_ship_group != null:
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


func set_formation_position(new_string):
	formation_position = new_string
	update_formation_position()


func update_formation_position():
	if label_formation != null:
		label_formation.text = tr("general.formation." + formation_position)


func reset_ship_queues_array():
	for queue in ship_queues_array:
		print_stack()
		queue.disconnect("finished", self, "_on_ship_queue_finished")
		queue.disconnect("canceled", self, "_on_ship_queue_canceled")
	ship_queues_array.clear()
	update_queue_process()
