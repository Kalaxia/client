class_name ScoreFaction
extends DictResource

const ASSETS = preload("res://resources/assets.tres")

export(Resource) var faction = null
export(int) var victory_points = 0


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
	faction = ASSETS.factions[faction_id as float] \
			if faction_id != null and ASSETS.factions.has(faction_id as float) \
			else  ASSETS.factions[0.0]
	emit_signal("changed")


static func get_max_points():
	return ASSETS.constants.victory_points
