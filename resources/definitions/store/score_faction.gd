class_name ScoreFaction
extends DictResource

signal score_updated()

const ASSETS = preload("res://resources/assets.tres")

export(Resource) var faction = null
export(int) var victory_points = 0 setget set_victory_points


func _init(dict = null).(dict):
	pass


func load_dict(dict):
	if dict == null: 
		return
	.load_dict(dict)
	if not dict is Dictionary or dict.has("faction"):
		set_faction(dict.faction)


func _get_dict_property_list():
	return ["victory_points"]


func set_faction(faction_id):
	faction = ASSETS.factions[faction_id] \
			if faction_id != null and ASSETS.factions.size() > faction_id \
			else  ASSETS.factions[0]
	emit_signal("changed")


func set_victory_points(new_int):
	victory_points = new_int
	emit_signal("score_updated")
	emit_signal("changed")


static func get_max_points():
	return ASSETS.constants.victory_points
