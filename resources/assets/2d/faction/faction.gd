extends DictResource
class_name KalaxiaFaction,"res://resources/assets/2d/white_logo.png"

export(Texture) var banner
export(Texture) var banner_icon
export(Color) var display_color
export(String) var display_name
export(Resource) var picto

func get_color(lighten = false) -> Color:
	if lighten:
		return Utils.lighten_color(self.display_color)
	else:
		return self.display_color

func load_dict(dict : Dictionary) -> void:

	var icon = Image.new()
	icon.load("res://resources/faction/{name}/banner.png".format(dict))
	var icon_tex := ImageTexture.new()
	icon_tex.create_from_image(icon)
	icon_tex.set_size_override(Vector2(50, 50))
	
	self.banner_icon = icon_tex

	self.banner = load("res://resources/faction/{name}/banner.png".format(dict))
	
	var color = []
	for i in range(0, 4):
		color.push_back((dict.faction_color >> (24 - i*8)) & 0xff)
	self.display_color = Color8(color[0], color[1], color[2], color[3])

	self.display_name = dict.name
	self.picto = load("res://resources/2d/picto.gd").of_faction(dict.name)

