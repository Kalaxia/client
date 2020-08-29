tool
extends DictResource
class_name KalaxiaFaction,"res://resources/assets/2d/white_logo.png"

export(Texture) var banner
export(Texture) var banner_icon
export(Color) var display_color
export(String) var display_name
export(Resource) var picto
export(Theme) var theme


func get_color(lighten = false) -> Color:
	if lighten:
		return Utils.lighten_color(self.display_color)
	else:
		return self.display_color


func load_dict(dict) -> void:
	var icon = Image.new()
	icon.load("res://resources/faction/{name}/banner.png".format(dict))
	var icon_tex := ImageTexture.new()
	icon_tex.create_from_image(icon)
	icon_tex.set_size_override(Vector2(50, 50))
	
	self.banner_icon = icon_tex

	self.banner = load("res://resources/faction/{name}/banner.png".format(dict))
	self.display_color = dict.display_color

	self.display_name = dict.name
	self.picto = KalaxiaPicto.of_faction(dict.name)
	self.theme = load("res://themes/theme_faction/{name}/theme_main.tres".format(dict))
