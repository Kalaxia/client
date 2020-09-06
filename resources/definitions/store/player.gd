class_name Player
extends DictResource

signal wallet_updated(wallet)
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
	return ["username", "lobby", "game", "ready", "is_connected", "id", "wallet"]


func set_wallet(new_amount):
	wallet = new_amount
	emit_signal("changed")
	emit_signal("wallet_updated", wallet)


func update_wallet(amount):
	self.wallet += amount


func update(dict : Dictionary):
	load_dict(dict)
	emit_signal("updated")


func set_faction(faction_id):
	faction = ASSETS.factions[faction_id] \
			if faction_id != null and ASSETS.factions.size() > faction_id \
			else ASSETS.factions[0]
	emit_signal("changed")
