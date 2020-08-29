extends Control

signal ship_construction_started(ship_queue)

var ship_category = assets.ship_models[0] setget set_ship_category
var _lock_build_ships = Utils.Lock.new()
var _quantity_orderred = 0
var _category_orderred = ""

onready var spinbox = $PanelContainer/HBoxContainer/SpinBox
onready var line_edit_spin_box = spinbox.get_line_edit()
onready var button_order = $PanelContainer/HBoxContainer/Button
onready var time_label = $PanelContainer/HBoxContainer/Time
onready var hit_point_label = $PanelContainer/HBoxContainer/HitPoint
onready var damage_label = $PanelContainer/HBoxContainer/Damage
onready var accuracy_label = $PanelContainer/HBoxContainer/Accuracy
onready var price_label = $PanelContainer/HBoxContainer/Price

const assets = preload("res://resources/assets.tres")

func _ready():
	button_order.connect("pressed", self, "_on_pressed_build")
	spinbox.connect("value_changed", self, "_on_spinbox_changed")
	Store.connect("wallet_updated", self, "_on_wallet_update")
	line_edit_spin_box.connect("text_changed", self, "_on_line_edit_text_changed")
	line_edit_spin_box.connect("text_entered", self, "_on_text_entered")
	update_elements()
	update_price_and_time()


func _on_line_edit_text_changed(text = null):
	var caret_position = line_edit_spin_box.caret_position
	spinbox.apply()
	line_edit_spin_box.caret_position = caret_position


func _on_text_entered(text = null):
	_on_pressed_build()


func _on_wallet_update(ammount):
	update_order_button_state()


func _on_spinbox_changed(value):
	update_price_and_time()


func update_order_button_state():
	if button_order != null:
		button_order.disabled = Store._state.player.wallet < spinbox.value * ship_category.cost


func update_price_and_time():
	if price_label != null:
		price_label.text = tr("hud.details.building.hangar.price %d") % (ship_category.cost * spinbox.value)
	if time_label != null:
		time_label.text = tr("hud.details.building.hangar.time %.1f") % (ship_category.construction_time * spinbox.value / 1000.0)
	update_order_button_state()


func update_elements():
	if ship_category != null:
		$PanelContainer/HBoxContainer/TextureRect.texture = assets.ship[ship_category.category]
		$PanelContainer/HBoxContainer/Label.text = tr("hud.details.building.hangar.ship_model %s") % tr("ship." + ship_category.category)
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


func _on_pressed_build():
	var quantity = spinbox.value
	if quantity > 0:
		build_ship(quantity)


func build_ship(quantity):
	if not _lock_build_ships.try_lock():
		return
	if Store._state.player.wallet < quantity * ship_category.cost:
		_lock_build_ships.unlock()
		Store.notify(tr("notification.error.not_enought_cred.title"), tr("notification.error.not_enought_cred.content"))
		return
	_quantity_orderred = quantity
	_category_orderred = ship_category
	Network.req(self, "_on_ship_build_requested",
		"/api/games/"+ Store._state.game.id + "/systems/" + Store._state.selected_system.id + "/ship-queues/",
		HTTPClient.METHOD_POST,
		[ "Content-Type: application/json" ],
		JSON.print({"category" : ship_category.category, "quantity" : quantity})
	)


func _on_ship_build_requested(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
	if response_code == HTTPClient.RESPONSE_CREATED or response_code == HTTPClient.RESPONSE_OK:
		var result = JSON.parse(body.get_string_from_utf8()).result
		Store.update_wallet(- _category_orderred.cost * _quantity_orderred)
		_quantity_orderred = 0
		_category_orderred = null
		emit_signal("ship_construction_started", result)
	_lock_build_ships.unlock()
