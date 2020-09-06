class_name Player
extends DictResource

signal wallet_updated()
signal updated()

const ASSETS = preload("res://resources/assets.tres")

export(String) var username
export(String) var id
export(Resource) var faction
export(String) var lobby
export(String) var game
export(bool) var ready
export(bool) var is_connected
export(int) var wallet = 0 setget set_wallet


func _init(dict = null).(dict):
	pass


func load_dict(dict : Dictionary) -> void:
	if dict == null:
		return
	.load_dict(dict)
	if not dict is Dictionary or dict.has("faction"):
		set_faction(dict.faction)


func _get_dict_property_list() -> Array:
	return ["username", "lobby", "game", "ready" , "is_connected", "id"]


func set_wallet(new_amount):
	wallet = new_amount
	emit_signal("changed")
	emit_signal("wallet_updated")


func update_wallet(amount):
	self.wallet += amount


func update(dict : Dictionary):
	load_dict(dict)
	emit_signal("updated")

func set_faction(faction_id):
	faction = ASSETS.factions[faction_id as float] \
			if faction_id != null and ASSETS.factions.has(faction_id as float) \
			else  ASSETS.factions[0.0]
	emit_signal("changed")
