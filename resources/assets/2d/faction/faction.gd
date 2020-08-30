tool
extends DictResource
class_name KalaxiaFaction,"res://resources/assets/2d/white_logo.png"

export(Texture) var banner
export(Texture) var banner_icon
export(Color) var display_color
export(String) var display_name
export(Resource) var picto
export(Theme) var theme
export(float) var id


func get_color(lighten = false) -> Color:
	if lighten:
		return Utils.lighten_color(self.display_color)
	else:
		return self.display_color


func load_dict(dict) -> void:
	var icon = Image.new()
	icon.load("res://resources/assets/2d/faction/%s/banner.png" % dict.name.to_lower())
	var icon_tex := ImageTexture.new()
	icon_tex.create_from_image(icon)
	icon_tex.set_size_override(Vector2(50, 50))
	
	self.banner_icon = icon_tex

	self.banner = load("res://resources/assets/2d/faction/%s/banner.png" % dict.name.to_lower())
	self.display_color = dict.display_color

	self.display_name = dict.name
	self.picto = KalaxiaPicto.of_faction(dict.name)
	self.theme = load("res://themes/theme_faction/%s/theme_main.tres" % dict.name.to_lower())
	id = dict.id
