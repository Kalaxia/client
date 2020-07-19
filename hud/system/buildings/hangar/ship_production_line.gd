extends Control


var ship_queue setget set_ship_queue

func _ready():
	$PanelContainer/hBoxContainer/Button.connect("pressed", self, "_on_button_cancel")
	update_elements()

func _process(delta):
	update_time()

func _on_button_cancel():
#	todo requ
	pass

func _on_cancel_construction(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
	if response_code == HTTPClient.RESPONSE_NO_CONTENT:
		queue_free()

func update_elements():
	if ship_queue == null:
		return
	$PanelContainer/hBoxContainer/TextureRect.texture = Utils.TEXTURE_SHIP_MODEL[ship_queue.model]
	$PanelContainer/hBoxContainer/ShipNumber.text = tr("hud.details.building.hangar.number_of_ships %d") % ship_queue.quantity
	$PanelContainer/hBoxContainer/ShipModel.text = tr("hud.details.building.hangar.ship_model %s") % tr("ship." + ship_queue.model) 
	update_time()

func update_time():
	if ship_queue == null:
		return
	var time_remaining = ship_queue.finished_at - OS.get_system_time_msecs()
	$PanelContainer/hBoxContainer/TimeRemaining.text = tr("hud.details.building.hangar.time_remaining %d") % floor(max(time_remaining, 0) / 1000.0 )
	var total_time =  (ship_queue.finished_at - ship_queue.created_at ) as float
	$PanelContainer/hBoxContainer/ProgressBar.value = (1.0 - time_remaining as float/ total_time) if total_time != 0 else 1

func set_ship_queue(ship_queue_new):
	ship_queue = ship_queue_new
	update_elements()
