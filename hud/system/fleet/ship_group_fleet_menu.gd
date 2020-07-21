extends Control

var ship_category = Utils.SHIP_CATEGORIES[0] setget set_ship_category 
var quantity_fleet = 0 setget set_quantity_fleet
var quantity_hangar = 0 setget set_quantity_hangar

func _ready():
	$PanelContainer/HBoxContainer/Button.connect("pressed", self, "_on_set_button")
	update_texture()
	update_quantities()

func update_texture():
	$PanelContainer/HBoxContainer/ShipModel.text = tr("hud.details.fleet.ship_model %s") % tr("ship." + ship_category)
	$PanelContainer/HBoxContainer/TextureModel.texture = Utils.TEXTURE_SHIP_CATEGORIES[ship_category]

func update_quantities():
	$PanelContainer/HBoxContainer/ShipFleet/Label.text = tr("hud.details.fleet.number_of_ship_fleet %d") % quantity_fleet
	$PanelContainer/HBoxContainer/ShipAvaliable/Label.text = tr("hud.details.fleet.number_of_ship_total %d") % (quantity_hangar + quantity_fleet)
	$PanelContainer/HBoxContainer/SpinBox.max_value = quantity_hangar + quantity_fleet

func _on_set_button():
	Network.req(self, "_on_ship_assigned",
		"/api/games/" + Store._state.game.id +
		"/systems/" + Store._state.selected_system.id +
		"/fleets/" + Store._state.selected_fleet.id +
		"/ship-groups/",
		HTTPClient.METHOD_POST,)

func _on_ship_asigned(fleet):
	pass

func set_ship_category(new_category):
	ship_category = new_category
	update_texture()

func set_quantity_fleet(quantity):
	quantity_fleet = max(quantity,0 )
	$PanelContainer/HBoxContainer/SpinBox.value = quantity_fleet
	update_quantities()

func set_quantity_hangar(quantity):
	quantity_hangar = max(quantity, 0)
	update_quantities()
