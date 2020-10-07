extends Resource
class_name KalaxiaPicto

export(Texture) var fleet_pin
export(Texture) var fleet_pin_noframe
export(Texture) var fleet
export(Texture) var system_circle
export(Texture) var system_disk
export(Texture) var crown_top
export(Texture) var crown_bottom


static func of_faction(faction : String):
	var ret = load("res://resources/assets/2d/picto.gd").new()
	ret.fleet_pin = load("res://resources/assets/2d/map/%s/fleet_pin.png" % faction)
	ret.fleet_pin_noframe = load("res://resources/assets/2d/map/%s/fleet_pin_noframe.png" % faction)
	ret.fleet = load("res://resources/assets/2d/map/%s/fleet.png" % faction)
	ret.system_circle = load("res://resources/assets/2d/map/%s/system_circle.png" % faction)
	ret.fleet_pin = load("res://resources/assets/2d/map/%s/system_disk.png" % faction)
	ret.crown_top = load("res://resources/assets/2d/map/%s/crown_top.png" % faction)
	ret.crown_bottom = load("res://resources/assets/2d/map/%s/crown_bottom.png" % faction)
	return ret


func system_by_kind(kind : String) -> Texture:
	match kind:
		"VictorySystem": return self.system_disk
		"BaseSystem": return self.system_circle
		var _x: return null
