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


func get_color(is_victory_system = false, is_current_player = false) -> Color:
	var color = self.display_color
	if is_victory_system:
		color = Utils.lighten_color(color)
	if is_current_player:
		color = Utils.lighten_color(color)
	return color


func update_info_form_dict(dict):
	self.display_color = dict.display_color
	self.display_name = dict.name
	self.id = dict.id


func load_dict(dict) -> void:
	# the loading of the icone does not wok in the complied version as it seatch 
	# for "res://resources/assets/2d/faction/%s/banner.png" in the file system
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
