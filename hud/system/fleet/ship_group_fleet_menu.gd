extends Control

var ship_category = Store._state.ship_models[0] setget set_ship_category 
var quantity_fleet = 0 setget set_quantity_fleet
var quantity_hangar = 0 setget set_quantity_hangar
var _quantity_assigned = 0
var _fleet_ship_assigned = null
var _lock_assign_ship = Utils.Lock.new()

onready var spinbox = $PanelContainer/HBoxContainer/SpinBox
onready var line_edit_spin_box = spinbox.get_line_edit()
onready var button_set = $PanelContainer/HBoxContainer/Button
onready var ship_category_label = $PanelContainer/HBoxContainer/ShipModel
onready var texture_rect_cathegory = $PanelContainer/HBoxContainer/TextureModel
onready var label_ship_fleet = $PanelContainer/HBoxContainer/ShipFleet/Label
onready var label_ship_total = $PanelContainer/HBoxContainer/ShipAvaliable/Label
onready var hit_point_label = $PanelContainer/HBoxContainer/HitPoint
onready var damage_label = $PanelContainer/HBoxContainer/Damage
onready var accuracy_label = $PanelContainer/HBoxContainer/Accuracy


func _ready():
	button_set.connect("pressed", self, "_on_set_button")
	update_elements()
	update_quantities()
	spinbox.value = quantity_fleet
	line_edit_spin_box.connect("text_changed", self, "_on_line_edit_text_changed")
	line_edit_spin_box.connect("text_entered", self, "_on_text_entered")


func _on_line_edit_text_changed(text = null):
	var caret_position = line_edit_spin_box.caret_position
	spinbox.apply()
	line_edit_spin_box.caret_position = caret_position


func update_elements():
	if ship_category_label != null:
		ship_category_label.text = tr("hud.details.fleet.ship_model %s") % tr("ship." + ship_category.category)
	if texture_rect_cathegory != null:
		texture_rect_cathegory.texture = Utils.TEXTURE_SHIP_CATEGORIES[ship_category.category]
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


func _on_text_entered(text = null):
	_on_set_button()


func _on_set_button():
	if not _lock_assign_ship.try_lock():
		return
	_quantity_assigned = spinbox.value
	_fleet_ship_assigned = Store._state.selected_fleet
	Network.req(self, "_on_ship_assigned",
			"/api/games/" + Store._state.game.id +
			"/systems/" + Store._state.selected_system.id +
			"/fleets/" + Store._state.selected_fleet.id +
			"/ship-groups/",
			HTTPClient.METHOD_POST,
			[ "Content-Type: application/json" ],
			JSON.print({"category" : ship_category.category, "quantity" : spinbox.value})
	)


func _on_ship_assigned(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
	if response_code == HTTPClient.RESPONSE_NO_CONTENT:
		quantity_hangar -= (_quantity_assigned - quantity_fleet)
		quantity_fleet = _quantity_assigned
		update_quantities()
		Store.update_fleet_nb_ships(_fleet_ship_assigned, ship_category.category, _quantity_assigned)
	_quantity_assigned = 0
	_fleet_ship_assigned = null
	_lock_assign_ship.unlock()


func set_ship_category(new_category):
	ship_category = new_category
	update_elements()


func set_quantity_fleet(quantity):
	quantity_fleet = max(quantity, 0)
	spinbox.value = quantity_fleet
	update_quantities()


func set_quantity_hangar(quantity):
	quantity_hangar = max(quantity, 0)
	update_quantities()
