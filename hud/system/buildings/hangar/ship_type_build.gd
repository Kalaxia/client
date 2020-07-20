extends Control

var ship_model = Utils.SHIP_MODEL[0] setget set_ship_model
var _lock_build_ships = Utils.Lock.new()
var _quantity_orderred = 0
var _model_orderred = ""

onready var spinbox = $PanelContainer/HBoxContainer/SpinBox
onready var button_order = $PanelContainer/HBoxContainer/Button

signal ship_construction_started(ship_queue)

func _ready():
	button_order.connect("pressed", self, "_on_pressed_build")
	spinbox.connect("value_changed", self, "_on_spinbox_changed")
	Store.connect("wallet_updated", self, "_on_wallet_update")
	update_elements()
	update_price()

func _on_wallet_update(ammount):
	update_order_button_state()

func _on_spinbox_changed(value):
	update_price()

func update_order_button_state():
	button_order.disabled = Store._state.player.wallet < spinbox.value * Utils.SHIP_PRICES[ship_model]

func update_price():
	$PanelContainer/HBoxContainer/Price.text = tr("hud.details.building.hangar.price %d") % (Utils.SHIP_PRICES[ship_model] * spinbox.value)
	update_order_button_state()

func update_elements():
	if ship_model != null:
		$PanelContainer/HBoxContainer/TextureRect.texture = Utils.TEXTURE_SHIP_MODEL[ship_model]
		$PanelContainer/HBoxContainer/Label.text = tr("hud.details.building.hangar.ship_model %s") % tr("ship." + ship_model)

func set_ship_model(new_model):
	if not Utils.SHIP_MODEL.has(new_model):
		return
	ship_model = new_model
	update_elements()
	update_price()

func _on_pressed_build():
	var quantity = spinbox.value
	if quantity > 0:
		build_ship(quantity)

func build_ship(quantity):
	if not _lock_build_ships.try_lock():
		return
	if Store._state.player.wallet <= quantity * Utils.SHIP_PRICES[ship_model] :
		_lock_build_ships.unlock()
		Store.notify(tr("notification.error.not_enought_cred.title"), tr("notification.error.not_enought_cred.content"))
		return
	_quantity_orderred = quantity
	_model_orderred = ship_model
	Network.req(self, "_on_ship_build_requested",
		"/api/games/"+ Store._state.game.id + "/systems/" + Store._state.selected_system.id + "/ship-queues/",
		HTTPClient.METHOD_POST,
		[ "Content-Type: application/json" ],
		JSON.print({"category" : ship_model, "quantity" : quantity})
	)

func _on_ship_build_requested(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
	if response_code == HTTPClient.RESPONSE_CREATED or response_code == HTTPClient.RESPONSE_OK:
		var result = JSON.parse(body.get_string_from_utf8()).result
		Store.update_wallet(-Utils.SHIP_PRICES[_model_orderred] * _quantity_orderred)
		_quantity_orderred = 0
		_model_orderred = ""
		emit_signal("ship_construction_started", result)
	_lock_build_ships.unlock()
