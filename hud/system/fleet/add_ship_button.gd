extends ButtonPanelContainer

signal build_ships_requested(quantity)

export(int) var quantity = 0 setget set_quantity
export(int) var price = 0 setget set_price

onready var label = $VBoxContainer/Label
onready var price_label = $VBoxContainer/price
onready var credits_texture = $VBoxContainer/TextureRectCred


func _ready():
	update_display()


func _pressed():
	._pressed()
	emit_signal("build_ships_requested", quantity)


func update_display():
	update_quantity_display()
	update_price_display()


func update_price_display():
	if price_label == null or credits_texture == null:
		return
	price_label.text = tr("hud.details.fleet.price %d") % price
	credits_texture.visible = price != 0
	price_label.visible = price != 0


func update_quantity_display():
	if label == null: 
		return
	if quantity > 0:
		label.text = tr("+ %d") % quantity
	elif quantity < 0:
		label.text = tr("- %d") % - quantity
	else:
		label.text = tr("0")


func set_quantity(new_quantity):
	quantity = new_quantity
	update_quantity_display()


func set_price(new_price):
	if new_price < 0: 
		return
	price = new_price
	update_price_display()
