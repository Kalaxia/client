extends Resource
class_name KalaxiaFaction,"res://resources/assets/2d/white_logo.png"

export(Texture) var banner
export(Color) var display_color
export(String) var display_name
export(Resource) var picto

func get_color(lighten = false) -> Color:
	if lighten:
		return Utils.lighten_color(self.display_color)
	else:
		return self.display_color

func load_dict(dict : Dictionary) -> void:
	self.banner = load("res://resources/faction/{faction}/banner.png".format(dict))
	self.display_color = Color(dict.color[0] / 255.0, dict.color[1] / 255.0, dict.color[2] / 255.0)
	self.display_name = dict.faction
	self.picto = load("res://resources/2d/picto.gd").of_faction(dict.faction)
