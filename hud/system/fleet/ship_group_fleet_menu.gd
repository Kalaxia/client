extends Control

#signal ship_assigned(ship_in_fleet, ship_in_hangar)
signal request_assignation(ship_category, quantity)
signal spinbox_too_much()
signal ship_category_changed()

const ASSETS : KalaxiaAssets = preload("res://resources/assets.tres")

export(bool) var build_ships = false setget set_build_ships

var ship_category : ShipModel = ASSETS.ship_models.values()[0] setget set_ship_category 
var quantity_fleet = 0 setget set_quantity_fleet
var quantity_hangar = 0 setget set_quantity_hangar
#var _lock_assign_ship = Utils.Lock.new() setget private_set, private_get
var _game_data : GameData = Store.game_data

onready var spinbox = $MarginContainer/Main/Assign/SpinBox
onready var button_set = $MarginContainer/Main/Assign/ButtonSet
onready var ship_category_label = $MarginContainer/Main/ShipModel/ShipModel
onready var texture_rect_cathegory = $MarginContainer/Main/ShipModel/TextureModel
onready var label_ship_fleet = $MarginContainer/Main/ShipFleet/Label
onready var label_ship_total = $MarginContainer/Main/ShipAvaliable/Label
onready var hit_point_label = $MarginContainer/Main/Stat/StatsL/StatHP/HitPoint
onready var damage_label = $MarginContainer/Main/Stat/StatsL/StatDamage/Damage
onready var accuracy_label = $MarginContainer/Main/Stat/StatR/StatAccuracy/Accuracy
onready var max_assign_button = $MarginContainer/Main/Assign/MaxAssign
onready var stat_price = $MarginContainer/Main/Stat/StatR/StatPrice/Price
onready var request_price = $MarginContainer/Main/ShipCost/Price
onready var ship_cost_container = $MarginContainer/Main/ShipCost
onready var select_ship_category_button = $MarginContainer/Main/ShipModel/OptionButton


func _ready():
	button_set.connect("pressed", self, "_on_set_button")
	update_elements()
	update_quantities()
	spinbox.value = quantity_fleet
	spinbox.connect("text_entered", self, "_on_text_entered")
	spinbox.connect("value_changed", self, "_on_value_changed_spinbox")
	max_assign_button.connect("pressed", self, "_on_max_assign_pressed")
	for model in ASSETS.ship_models.values():
		select_ship_category_button.add_item(tr("ship." + model.category))
	select_ship_category_button.selected = 0
	select_ship_category_button.connect("item_selected", self, "_on_model_selected")

func set_build_ships(boolean):
	build_ships = boolean
	update_quantities()


func update_elements():
	if select_ship_category_button != null:
		select_ship_category_button.selected = ASSETS.ship_models.keys().find(ship_category.category)
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
	if stat_price != null:
		stat_price.text = tr("hud.details.fleet.price %d") % ship_category.cost


func update_quantities():
	if label_ship_fleet == null or label_ship_total== null or spinbox == null or select_ship_category_button == null:
		return
	select_ship_category_button.disabled = quantity_fleet > 0
	label_ship_fleet.text = tr("hud.details.fleet.number_of_ship_fleet %d %d") % [quantity_fleet, quantity_hangar + quantity_fleet]
	label_ship_total.text = tr("hud.details.fleet.number_of_ship_total %d") % (quantity_hangar)
	var previous_spinbox_value = spinbox.value
	spinbox.max_value = quantity_hangar + quantity_fleet + \
			(floor(_game_data.player.wallet as float / ship_category.cost as float) as int \
			if build_ships else 0)
	spinbox.value = min(previous_spinbox_value, spinbox.max_value)
	if max_assign_button != null:
		max_assign_button.text = tr("hud.details.fleet.max_assign %d") % (quantity_hangar + quantity_fleet)
	_update_price()


func _on_value_changed_spinbox(_value):
	if spinbox.value > spinbox.max_value:
		spinbox.value = spinbox.max_value
		if not build_ships:
			emit_signal("spinbox_too_much")
	_update_price()


func _update_price():
	if spinbox == null or ship_cost_container == null or request_price == null:
		return
	var value = spinbox.value
	var need_building_ships = value > quantity_hangar + quantity_fleet
	ship_cost_container.visible = need_building_ships
	if need_building_ships:
		var cost = (value - (quantity_hangar + quantity_fleet)) * ship_category.cost
		request_price.text = tr("hud.details.fleet.price %d") % cost


func _on_text_entered(_text = null):
	_on_set_button()


func _on_max_assign_pressed():
	_request_assignation(quantity_hangar + quantity_fleet)


func _on_set_button():
	_request_assignation(spinbox.value)


func _request_assignation(quantity):
	emit_signal("request_assignation", ship_category, quantity)


func set_ship_category(new_category):
	var emit_signal_changed = ship_category != new_category
	ship_category = new_category
	update_elements()
	if emit_signal_changed:
		emit_signal("ship_category_changed")


func set_quantity_fleet(quantity):
	quantity_fleet = max(quantity, 0)
	update_quantities()
	spinbox.value = quantity_fleet


func set_quantity_hangar(quantity):
	quantity_hangar = max(quantity, 0)
	update_quantities()


#func private_set(_variant):
#	pass
#
#
#func private_get():
#	return null


func _on_model_selected(index):
	set_ship_category(ASSETS.ship_models.values()[index])
