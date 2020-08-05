extends Control

var ship_queue setget set_ship_queue

onready var cancel_button = $PanelContainer/hBoxContainer/Button
onready var texture_rect_category = $PanelContainer/hBoxContainer/TextureCategory
onready var ship_number_label = $PanelContainer/hBoxContainer/ShipNumber
onready var ship_category_label = $PanelContainer/hBoxContainer/ShipModel
onready var time_remaining_label = $PanelContainer/hBoxContainer/TimeRemaining
onready var progress_bar_time = $PanelContainer/hBoxContainer/ProgressBar

const assets : KalaxiaAssets = preload("res://resources/assets.tres")

func _ready():
	cancel_button.connect("pressed", self, "_on_button_cancel")
	update_elements()


func _process(delta):
	update_time()


func update_elements():
	if ship_queue == null:
		return
	if texture_rect_category != null:
		texture_rect_category.texture = assets.ship[ship_queue.category]
	if ship_number_label != null:
		ship_number_label.text = tr("hud.details.building.hangar.number_of_ships %d") % ship_queue.quantity
	if ship_category_label != null:
		ship_category_label.text = tr("hud.details.building.hangar.ship_model %s") % tr("ship." + ship_queue.category) 
	update_time()


func update_time():
	if ship_queue == null:
		return
	if time_remaining_label != null and progress_bar_time != null:
		var time_remaining = ship_queue.finished_at - OS.get_system_time_msecs()
		time_remaining_label.text = tr("hud.details.building.hangar.time_remaining %d") % floor(max(time_remaining, 0) / 1000.0 )
		var total_time =  (ship_queue.finished_at - ship_queue.started_at ) as float
		progress_bar_time.value = (1.0 - time_remaining as float/ total_time) if total_time != 0 else 1


func set_ship_queue(ship_queue_new):
	ship_queue = ship_queue_new
	update_elements()


func _on_button_cancel():
	# todo requ
	pass


func _on_cancel_construction(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
	if response_code == HTTPClient.RESPONSE_NO_CONTENT:
		queue_free()
