extends Control

signal ship_construction_started(ship_queue)

const ASSETS = preload("res://resources/assets.tres")

var _game_data : GameData = Store.game_data
var ship_category = ASSETS.ship_models.values()[0] setget set_ship_category
var _lock_build_ships = Utils.Lock.new() setget private_set, private_get

onready var spinbox = $PanelContainer/HBoxContainer/SpinBox
onready var button_order = $PanelContainer/HBoxContainer/Button
onready var time_label = $PanelContainer/HBoxContainer/Time
onready var hit_point_label = $PanelContainer/HBoxContainer/HitPoint
onready var damage_label = $PanelContainer/HBoxContainer/Damage
onready var accuracy_label = $PanelContainer/HBoxContainer/Accuracy
onready var price_label = $PanelContainer/HBoxContainer/Price
onready var request_max_button = $PanelContainer/HBoxContainer/RequestMax
onready var label_model = $PanelContainer/HBoxContainer/Label
onready var texture_model = $PanelContainer/HBoxContainer/TextureRect


func _ready():
	_lock_build_ships.connect("changed_state", self, "_on_lock_changed_state")
	button_order.connect("pressed", self, "_on_pressed_build")
	spinbox.connect("value_changed", self, "_on_spinbox_changed")
	_game_data.player.connect("wallet_updated", self, "_on_wallet_update")
	spinbox.connect("text_entered", self, "_on_text_entered")
	request_max_button.connect("pressed", self, "_on_request_max")
	update_elements()
	update_price_and_time()
	_update_max_values()


func _on_text_entered(_text = null):
	_on_pressed_build()


func _on_wallet_update(_amount):
	update_order_button_state()
	_update_max_values()


func _on_spinbox_changed(_value):
	update_price_and_time()


func _update_max_values():
	if spinbox == null or request_max_button == null:
		return
	spinbox.max_value = get_max_buildable_ships()
	request_max_button.text = tr("hud.system.building.hangar.build_max %d") % get_max_buildable_ships()
	_check_button_eabled_status()


func get_max_buildable_ships():
	return floor(_game_data.player.wallet / ship_category.cost) as int


func _on_lock_changed_state(_state):
	if button_order == null or request_max_button == null:
		return
	_check_button_eabled_status()


func _check_button_eabled_status():
	button_order.disabled = _lock_build_ships.get_is_locked() or _game_data.player.wallet < spinbox.value * ship_category.cost
	request_max_button.disabled = _lock_build_ships.get_is_locked() or get_max_buildable_ships() as int <= 0


func update_order_button_state():
	if button_order != null:
		_check_button_eabled_status()


func update_price_and_time():
	if price_label != null:
		price_label.text = tr("hud.details.building.hangar.price %d") % (ship_category.cost * spinbox.value)
	if time_label != null:
		time_label.text = tr("hud.details.building.hangar.time %.1f") % (ship_category.construction_time * spinbox.value / 1000.0)
	update_order_button_state()


func update_elements():
	if ship_category == null:
		return
	if texture_model != null:
		texture_model.texture = ship_category.texture
	if label_model != null:
		label_model.text = tr("hud.details.building.hangar.ship_model %s") % tr("ship." + ship_category.category)
	if hit_point_label != null:
		hit_point_label.text = tr("hud.details.building.hangar.hit_point %d") % ship_category.hit_points
	if damage_label != null:
		damage_label.text = tr("hud.details.building.hangar.damage %d") % ship_category.damage
	if accuracy_label != null:
		accuracy_label.text = tr("hud.details.building.hangar.accuracy %d") % ship_category.precision


func set_ship_category(new_category):
	ship_category = new_category
	update_elements()
	update_price_and_time()
	_update_max_values()


func _on_pressed_build():
	var quantity = spinbox.value
	if quantity > 0:
		build_ship(quantity)


func _on_request_max():
	build_ship(get_max_buildable_ships())


func build_ship(quantity):
	if not _lock_build_ships.try_lock():
		return
	if _game_data.player.wallet < quantity * ship_category.cost:
		_lock_build_ships.unlock()
		Store.notify(tr("notification.error.not_enought_cred.title"), tr("notification.error.not_enought_cred.content"))
		return
	Network.req(self, "_on_ship_build_requested",
		"/api/games/" + _game_data.id + "/systems/" + _game_data.selected_state.selected_system.id + "/ship-queues/",
		HTTPClient.METHOD_POST,
		[ "Content-Type: application/json" ],
		JSON.print({"category" : ship_category.category, "quantity" : quantity}),
		[quantity, ship_category, _game_data.selected_state.selected_system]
	)


func _on_ship_build_requested(err, response_code, _headers, body, quantity, category, system : System):
	if err:
		ErrorHandler.network_response_error(err)
	if response_code == HTTPClient.RESPONSE_CREATED or response_code == HTTPClient.RESPONSE_OK:
		var result = JSON.parse(body.get_string_from_utf8()).result
		_game_data.player.update_wallet( - category.cost * quantity)
		emit_signal("ship_construction_started", result)
		# todo add shipqueue in game_data
	_lock_build_ships.unlock()


func private_set(_variant):
	pass


func private_get():
	return null
