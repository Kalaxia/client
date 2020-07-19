extends Control

var ship_model = Utils.SHIP_MODEL[0] setget set_ship_model 
var quantity_fleet = 0 setget set_quantity_fleet
var quantity_hangar = 0 setget set_quantity_hangar

func _ready():
	$PanelContainer/HBoxContainer/Button.connect("pressed", self, "_on_set_button")
	update_texture()
	update_quantities()

func update_texture():
	$PanelContainer/HBoxContainer/ShipModel.text = tr("hud.details.fleet.ship_model %s") % tr("ship." + ship_model)
	$PanelContainer/HBoxContainer/TextureModel.texture = Utils.TEXTURE_SHIP_MODEL[ship_model]

func update_quantities():
	$PanelContainer/HBoxContainer/ShipFleet/Label.text = tr("hud.details.fleet.number_of_ship_fleet %d") % quantity_fleet
	$PanelContainer/HBoxContainer/ShipAvaliable/Label.text = tr("hud.details.fleet.number_of_ship_total %d") % (quantity_hangar + quantity_fleet)
	$PanelContainer/HBoxContainer/SpinBox.max_value = quantity_hangar + quantity_fleet

func _on_set_button():
	# todo request
	pass

func _on_ship_asigned(fleet):
	pass

func set_ship_model(new_model):
	ship_model =  new_model
	update_texture()

func set_quantity_fleet(quantity):
	quantity_fleet = max(quantity,0 )
	$PanelContainer/HBoxContainer/SpinBox.value = quantity_fleet
	update_quantities()

func set_quantity_hangar(quantity):
	quantity_hangar = max(quantity, 0)
	update_quantities()
