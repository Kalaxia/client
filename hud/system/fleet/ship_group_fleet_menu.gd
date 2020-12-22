extends Control

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
onready var buttons_add_ships = [
	$MarginContainer/Main/HBoxButtonAdd/Button0,
	$MarginContainer/Main/HBoxButtonAdd/Button1,
	$MarginContainer/Main/HBoxButtonAdd/Button2,
	$MarginContainer/Main/HBoxButtonAdd/Button3,
]


func _ready():
	button_set.connect("pressed", self, "_on_set_button")
	update_elements()
	update_quantities()
	update_buttons()
	reset_spinbox_quantity()
	spinbox.connect("text_entered", self, "_on_text_entered")
	spinbox.connect("value_changed", self, "_on_value_changed_spinbox")
	max_assign_button.connect("pressed", self, "_on_max_assign_pressed")
	for model in ASSETS.ship_models.values():
		select_ship_category_button.add_item(tr("ship." + model.category))
	select_ship_category_button.selected = 0
	select_ship_category_button.connect("item_selected", self, "_on_model_selected")
	_game_data.player.connect("wallet_updated", self, "_on_wallet_update")
	for node in buttons_add_ships:
		node.connect("build_ships_requested", self, "_on_build_ships_requested")


func set_build_ships(boolean):
	build_ships = boolean
	update_quantities()
	update_buttons()


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
	_update_max_quanity()
	if max_assign_button != null:
		max_assign_button.text = tr("hud.details.fleet.max_assign %d") % (quantity_hangar + quantity_fleet)
	_update_price()


func _update_max_quanity():
	var previous_spinbox_value = spinbox.value
	spinbox.max_value = quantity_hangar + quantity_fleet + \
			(ship_category.max_ship_build(_game_data.player.wallet) \
			if build_ships else 0)
	spinbox.value = min(previous_spinbox_value, spinbox.max_value)


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
	update_buttons()


func set_quantity_hangar(quantity):
	quantity_hangar = max(quantity, 0)
	update_buttons()
	update_quantities()


func _on_model_selected(index):
	set_ship_category(ASSETS.ship_models.values()[index])


func _on_wallet_update(_amount):
	if build_ships:
		_update_max_quanity()
		update_buttons()



func update_buttons():
	if buttons_add_ships != null:
		var proposition = get_proposition_assignation(_game_data.player.wallet, quantity_hangar, buttons_add_ships.size() - 1, ship_category)
		# the result at this point is an array that gives the factors for the button quantity that we can build
		for index in range(buttons_add_ships.size()):
			var button = buttons_add_ships[index]
			if index == 0:
				button.quantity = - quantity_fleet
				button.price = 0
				button.disabled = quantity_fleet == 0
			else:
				var quantity_to_add = proposition[proposition.size() - 1 - (index - 1)]
				var price = Utils.int_max(quantity_to_add - quantity_hangar, 0) * ship_category.cost
				button.quantity = quantity_to_add
				button.price = price
				button.disabled = (not build_ships and quantity_to_add > quantity_hangar) \
						or price > _game_data.player.wallet or quantity_to_add == 0


static func get_proposition_assignation(credits, number_in_hangar, number_of_proposition, ship_model):
	var SELECTED_SIGNIFICANT_NUMBER = [5, 2, 1] # this array need to be sorted bigest to smalest, no number bigger than 9
	var max_ships = ship_model.max_ship_build(credits) + number_in_hangar
	var log_10 = (log(max_ships as float) / log(10.0)) if max_ships != 0 else 0.0
	var fist_significant_number = floor(max_ships / (pow(10.0, floor(log_10)))) as int
	# we need to find in this array the position of the bigest significant number
	# that is smaller or equal to our significant number
	var index_significant = SELECTED_SIGNIFICANT_NUMBER.size() - 1 # at worst this is the last item
	for index in range(SELECTED_SIGNIFICANT_NUMBER.size()):
		if fist_significant_number >= SELECTED_SIGNIFICANT_NUMBER[index]:
			index_significant = index
			break
	var proposition = []
	var has_attain_minimum = false
	var index_minimum_attained = 0
	for index in range(number_of_proposition):
		if not has_attain_minimum:
			var new_index = index + index_significant # this always bigger or equal to 0
			var factor = 1.0
			while new_index >= SELECTED_SIGNIFICANT_NUMBER.size():
				new_index -= SELECTED_SIGNIFICANT_NUMBER.size()
				factor *= 0.1
			var new_number = SELECTED_SIGNIFICANT_NUMBER[new_index] as float * factor * pow(10.0, floor(log_10))
			if new_number < 1.0:
				# we do not show proposition smaller than 0 so we add up bigger proposition
				has_attain_minimum = true
				index_minimum_attained = index
			else:
				proposition.push_back(floor(new_number) as int)
		# we recheck the if as it may has changed 
		if has_attain_minimum:
			var new_index = index_significant - 1 + (index_minimum_attained - index) # this is always smaller to SELECTED_SIGNIFICANT_NUMBER.size()
			var factor = 1.0
			while new_index < 0:
				new_index += SELECTED_SIGNIFICANT_NUMBER.size()
				factor *= 10.0
			var new_number = SELECTED_SIGNIFICANT_NUMBER[new_index] as float * factor * pow(10.0, floor(log_10))
			proposition.push_front(floor(new_number) as int)
	return proposition


func _on_build_ships_requested(quantity):
	_request_assignation(quantity + quantity_fleet)


func reset_spinbox_quantity():
	spinbox.value = quantity_fleet
