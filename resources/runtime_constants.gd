extends DictResource
class_name RuntimeConstants

var fleet_range
var victory_points
var victory_points_per_minute

func _get_dict_property_list() -> Array:
	return ["fleet_range", "victory_points", "victory_points_per_minute"]
