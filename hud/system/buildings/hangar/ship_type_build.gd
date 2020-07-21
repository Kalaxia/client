extends Control

var ship_category = Utils.SHIP_CATEGORIES[0] setget set_ship_category
var _lock_build_ships = Utils.Lock.new()
var _quantity_orderred = 0
var _category_orderred = ""

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
	button_order.disabled = Store._state.player.wallet < spinbox.value * Utils.SHIP_PRICES[ship_category]

func update_price():
	$PanelContainer/HBoxContainer/Price.text = tr("hud.details.building.hangar.price %d") % (Utils.SHIP_PRICES[ship_category] * spinbox.value)
	update_order_button_state()

func update_elements():
	if ship_category != null:
		$PanelContainer/HBoxContainer/TextureRect.texture = Utils.TEXTURE_SHIP_CATEGORIES[ship_category]
		$PanelContainer/HBoxContainer/Label.text = tr("hud.details.building.hangar.ship_model %s") % tr("ship." + ship_category)

func set_ship_category(new_category):
	if not Utils.SHIP_CATEGORIES.has(new_category):
		return
	ship_category = new_category
	update_elements()
	update_price()

func _on_pressed_build():
	var quantity = spinbox.value
	if quantity > 0:
		build_ship(quantity)

func build_ship(quantity):
	if not _lock_build_ships.try_lock():
		return
	if Store._state.player.wallet <= quantity * Utils.SHIP_PRICES[ship_category] :
		_lock_build_ships.unlock()
		Store.notify(tr("notification.error.not_enought_cred.title"), tr("notification.error.not_enought_cred.content"))
		return
	_quantity_orderred = quantity
	_category_orderred = ship_category
	Network.req(self, "_on_ship_build_requested",
		"/api/games/"+ Store._state.game.id + "/systems/" + Store._state.selected_system.id + "/ship-queues/",
		HTTPClient.METHOD_POST,
		[ "Content-Type: application/json" ],
		JSON.print({"category" : ship_category, "quantity" : quantity})
	)

func _on_ship_build_requested(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
	if response_code == HTTPClient.RESPONSE_CREATED or response_code == HTTPClient.RESPONSE_OK:
		var result = JSON.parse(body.get_string_from_utf8()).result
		Store.update_wallet(-Utils.SHIP_PRICES[_category_orderred] * _quantity_orderred)
		_quantity_orderred = 0
		_category_orderred = ""
		emit_signal("ship_construction_started", result)
	_lock_build_ships.unlock()
