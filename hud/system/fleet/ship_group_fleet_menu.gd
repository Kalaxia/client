extends Control

signal ship_assigned(ship_in_fleet, ship_in_hangar)

const ASSETS : KalaxiaAssets = preload("res://resources/assets.tres")

var ship_category : ShipModel = ASSETS.ship_models.values()[0] setget set_ship_category 
var quantity_fleet = 0 setget set_quantity_fleet
var quantity_hangar = 0 setget set_quantity_hangar
var _lock_assign_ship = Utils.Lock.new() setget private_set, private_get
var _game_data : GameData = load(GameData.PATH_NAME)


onready var spinbox = $PanelContainer/HBoxContainer/SpinBox
onready var button_set = $PanelContainer/HBoxContainer/Button
onready var ship_category_label = $PanelContainer/HBoxContainer/ShipModel
onready var texture_rect_cathegory = $PanelContainer/HBoxContainer/TextureModel
onready var label_ship_fleet = $PanelContainer/HBoxContainer/ShipFleet/Label
onready var label_ship_total = $PanelContainer/HBoxContainer/ShipAvaliable/Label
onready var hit_point_label = $PanelContainer/HBoxContainer/HitPoint
onready var damage_label = $PanelContainer/HBoxContainer/Damage
onready var accuracy_label = $PanelContainer/HBoxContainer/Accuracy
onready var max_assign_button = $PanelContainer/HBoxContainer/MaxAssign


func _ready():
	button_set.connect("pressed", self, "_on_set_button")
	update_elements()
	update_quantities()
	spinbox.value = quantity_fleet
	spinbox.connect("text_entered", self, "_on_text_entered")
	max_assign_button.connect("pressed", self, "_on_max_assign_pressed")


func update_elements():
	if ship_category_label != null:
		ship_category_label.text = tr("hud.details.fleet.ship_model %s") % tr("ship." + ship_category.category)
	if texture_rect_cathegory != null:
		texture_rect_cathegory.texture = ship_category.texture
	if hit_point_label != null:
		hit_point_label.text = tr("hud.details.fleet.hit_point %d") % ship_category.hit_points
	if damage_label != null:
		damage_label.text = tr("hud.details.fleet.damage %d") % ship_category.damage
	if accuracy_label != null:
		accuracy_label.text = tr("hud.details.fleet.accuracy %d") % ship_category.precision


func update_quantities():
	label_ship_fleet.text = tr("hud.details.fleet.number_of_ship_fleet %d %d") % [quantity_fleet, quantity_hangar + quantity_fleet]
	label_ship_total.text = tr("hud.details.fleet.number_of_ship_total %d") % (quantity_hangar)
	var previous_spinbox_value = spinbox.value
	spinbox.max_value = quantity_hangar + quantity_fleet
	spinbox.value = min(previous_spinbox_value, spinbox.max_value)
	if max_assign_button != null:
		max_assign_button.text = tr("hud.details.fleet.max_assign %d") % (quantity_hangar + quantity_fleet)


func _on_text_entered(_text = null):
	_on_set_button()


func _on_max_assign_pressed():
	_request_assignation(quantity_hangar + quantity_fleet)


func _on_set_button():
	_request_assignation(spinbox.value)


func _request_assignation(quantity):
	if not _lock_assign_ship.try_lock():
		return
	Network.req(self, "_on_ship_assigned",
			"/api/games/" + _game_data.id +
			"/systems/" + _game_data.selected_state.selected_system.id +
			"/fleets/" + _game_data.selected_state.selected_fleet.id +
			"/ship-groups/",
			HTTPClient.METHOD_POST,
			[ "Content-Type: application/json" ],
			JSON.print({"category" : ship_category.category, "quantity" : quantity}),
			[quantity, _game_data.selected_state.selected_fleet]
	)


func _on_ship_assigned(err, response_code, _headers, _body, quantity, fleet : Fleet):
	if err:
		ErrorHandler.network_response_error(err)
	if response_code == HTTPClient.RESPONSE_NO_CONTENT:
		quantity_hangar -= (quantity - quantity_fleet)
		quantity_fleet = quantity
		update_quantities()
		fleet.update_fleet_nb_ships(ship_category.category, quantity)
		emit_signal("ship_assigned", quantity_fleet, quantity_hangar)
	_lock_assign_ship.unlock()


func set_ship_category(new_category):
	ship_category = new_category
	update_elements()


func set_quantity_fleet(quantity):
	quantity_fleet = max(quantity, 0)
	update_quantities()
	spinbox.value = quantity_fleet


func set_quantity_hangar(quantity):
	quantity_hangar = max(quantity, 0)
	update_quantities()


func private_set(_variant):
	pass


func private_get():
	return null
