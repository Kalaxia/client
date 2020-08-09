extends Node

############## CONSTANTS ##############

const AUDIO_VOLUME_DB_MIN = -100.0 # in dB
const SCALE_SYSTEMS_COORDS = 20

############## TEXTURES ##############

const BANNERS = {
	1 : preload("res://resources/assets/2d/faction/kalankar/banner.png"),
	2 : preload("res://resources/assets/2d/faction/valkar/banner.png"),
	3 : preload("res://resources/assets/2d/faction/adranite/banner.png"),
}

const BANNERS_SMALL = {
	1 : preload("res://resources/assets/2d/faction/kalankar/banner_image.png"),
	2 : preload("res://resources/assets/2d/faction/valkar/banner_image.png"),
	3 : preload("res://resources/assets/2d/faction/adranite/banner_image.png"),
}

const TEXTURE_CROWN_FLEET = {
	1 : preload("res://resources/assets/2d/map/kalankar/picto_flotte_couronne-01.png"),
	2 : preload("res://resources/assets/2d/map/valkar/picto_flotte_couronne-01.png"),
	3 : preload("res://resources/assets/2d/map/adranite/picto_flotte_couronne-01.png"),
}
const FLEET_TEXTURE = {
	0 : preload("res://resources/assets/2d/map/picto_flotte_2.png"),
	1 : preload("res://resources/assets/2d/map/kalankar/picto_flotte_2.png"),
	2 : preload("res://resources/assets/2d/map/valkar/picto_flotte_2.png"),
	3 : preload("res://resources/assets/2d/map/adranite/picto_flotte_2.png"),
}
const TEXTURE_CROWN_SYSTEM = {
	1 : preload("res://resources/assets/2d/map/kalankar/couronne.png"),
	2 : preload("res://resources/assets/2d/map/valkar/couronne.png"),
	3 : preload("res://resources/assets/2d/map/adranite/couronne.png"),
}
const TEXTURE_SYSTEM = {
	"VictorySystem":{
		0 : preload("res://resources/assets/2d/map/picto_syteme.png"),
		1 : preload("res://resources/assets/2d/map/kalankar/picto_syteme_masque_v2-01.png"),
		2 : preload("res://resources/assets/2d/map/valkar/picto_syteme_serpent_v2-01.png"),
		3 : preload("res://resources/assets/2d/map/adranite/picto_syteme_epee_v2-01.png"),
	},
	"BaseSystem"  : {
		0 : preload("res://resources/assets/2d/map/picto_syteme_1_neutral.png"),
		1 : preload("res://resources/assets/2d/map/kalankar/picto_syteme_masque-01.png"),
		2 : preload("res://resources/assets/2d/map/valkar/picto_syteme_serpent-01.png"),
		3 : preload("res://resources/assets/2d/map/adranite/picto_systeme_epee-01.png"),
	},
}

const TEXTURE_SHIP_CATEGORIES = {
	"" : preload("res://resources/assets/2d/picto/ships/ship_64px.png"),
	"fighter" : preload("res://resources/assets/2d/picto/ships/fighter.svg"),
	"corvette" : preload("res://resources/assets/2d/picto/ships/corvette.svg"),
	"frigate" : preload("res://resources/assets/2d/picto/ships/frigate.svg"),
	"cruiser" : preload("res://resources/assets/2d/picto/ships/cruiser.svg"),
}
const TEXTURE_BUILDING = {
	"" : preload("res://resources/assets/2d/picto/building/area.png"),
	"shipyard" : preload("res://resources/assets/2d/picto/building/shipyard_64px.png"),
	"mine" : preload("res://resources/assets/2d/picto/building/mine.svg"),
	"portal" : preload("res://resources/assets/2d/picto/building/portal.svg"),
}
const THEME_FACTION = {
	0 : preload("res://themes/theme_u_main.tres"),
	1 : preload("res://themes/theme_faction/valankar/theme_main.tres"),
	2 : preload("res://themes/theme_faction/valkar/theme_main.tres"),
	3 : preload("res://themes/theme_faction/adranite/theme_main.tres"),
}

############## varaibles ##############

var fleet_range
var victory_point_max
var victory_point_per_minute

############## LOCK ##############

class Lock:
	extends Reference
	
	signal locked()
	signal unlocked()
	signal changed_state(lock_state)
	
	enum LOCK_STATE {
		BUSY = 0,
		OK = 1,
	} # can be used in if directly like they are bools
	enum CAN_LOCK_STATE{
		CANNOT_LOCK = 0,
		CAN_LOCK = 1,
	}
	
	var _is_locked = false setget _private_setter, get_is_locked
	
	
	func _private_setter(variable):
		# cannot be set from outisde
		pass
	
	
	func get_is_locked():
		return _is_locked
	
	
	func try_lock():
		if _is_locked:
			return LOCK_STATE.BUSY
		_is_locked = true
		emit_signal("locked")
		emit_signal("changed_state", true)
		return LOCK_STATE.OK
	
	
	func unlock():
		var previous_state = _is_locked
		_is_locked = false
		if previous_state:
			emit_signal("unlocked")
			emit_signal("changed_state", false)
		return previous_state
	
	
	func can_lock():
		return CAN_LOCK_STATE.CANNOT_LOCK if _is_locked else CAN_LOCK_STATE.CAN_LOCK


############## METHODS ##############


func _ready():
	pass


func get_label_of_event(event):
	if event is InputEventKey:
		return event.as_text()
	if event is InputEventMouseButton:
		return tr("action.key.mouse_key_" + (event.button_index as String))
	return ""


func set_constants(constants):
	fleet_range = constants.fleet_range
	victory_point_max = constants.victory_points
	victory_point_per_minute = constants.victory_points_per_minute


func has_constants():
	return fleet_range != null and victory_point_max != null and victory_point_per_minute != null

############## STATICS METHODS ##############

static func set_window_resizable(is_resizable):
	var size = OS.window_size
	var position = OS.window_position
	if OS.window_resizable == is_resizable:
		return
	OS.set_window_resizable(is_resizable)
	OS.min_window_size = Vector2(1280, 720) if is_resizable else Vector2.ZERO

static func lighten_color(color):
	color.r = min(color.r + 40.0 / 255.0, 1.0)
	color.g = min(color.g + 40.0 / 255.0, 1.0)
	color.b = min(color.b + 40.0 / 255.0, 1.0)
	return color
