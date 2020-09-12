extends RemoteDictResource
class_name ConstanteRemoteResource

export(float) var fleet_range = null
export(int) var victory_points_per_minute = null


func _init(url = "/api/constants/", dict = null).(url, dict):
	pass


func _get_dict_property_list():
	return ["fleet_range", "victory_points_per_minute"]
