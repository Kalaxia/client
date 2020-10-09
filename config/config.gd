extends Node

signal locale_reloaded()

const PATH_CONFIG_NETWORK = "res://config/environment_config.tres"
const CONFIG_DIR = "res://"
const PATH_CONFIG_USER = CONFIG_DIR + "config.cfg"


# set of key bindings that can be modified in the menu 
const ENABLE_KEY_BINDING_CHANGE = [
	"ui_zoom_out_map",
	"ui_zoom_in_map",
	"ui_drag_map",
	"ui_move_map_up",
	"ui_move_map_down",
	"ui_move_map_left",
	"ui_move_map_right",
	"ui_add_fleet",
	"ui_map_center_system",
	"ui_hud_scores",
	"ui_minimize",
]
const KEY_BINDING_SECTION_NAME = "Key binding"
const SOUND_SECTION_NAME = "Audio"
const GRAPHICS_SECTION_NAME = "Graphics"
const MAXIMIZE_CONFIG_NAME = "Maximize"
const FULLSCREEN_CONFIG_NAME = "Fullscreen"
const RESOLUTION_CONFIG_NAME = "Resolution"
const SCREEN_CONFIG_NAME = "Display_id"
const LOCALE_SECTION_NAME = "Language"
const LOCALE_CONFIG_NAME = "local"

const DEFAULT_LOCALE = "fr"
const VERSION = preload("res://version.tres")

var api = {
	'dns': null,
	'port': null,
	'scheme': null,
	'ws_scheme': null
}
var config_environment = preload(PATH_CONFIG_NETWORK)
var config_user = ConfigFile.new()


func _ready():
	print("Version : %s" % VERSION.version)
	api = _get_api_config(config_environment)
	var err_config_user = config_user.load(PATH_CONFIG_USER)
	if err_config_user == OK:
		_load_config_user(config_user)
	else:
		print( tr("error while parsing configuration file %s : %s ") % [ PATH_CONFIG_USER, str(err_config_user)] )
		# by default we try to borerless maximize
		_load_default_settings()


func set_key_binding(action : String):
	var events_to_save = {"keys": [] ,"mouse": []}
	for event in InputMap.get_action_list(action):
		if event is InputEventKey:
			events_to_save.keys.push_back(event.scancode)
		elif event is InputEventMouseButton:
			events_to_save.mouse.push_back(event.button_index)
	config_user.set_value(KEY_BINDING_SECTION_NAME, action, events_to_save)


func set_audio_volume(bus_name: String,linear_volume : float) -> void:
	config_user.set_value(SOUND_SECTION_NAME, bus_name.replace(" ", "_"), linear_volume)


func save_config_file():
	var err = config_user.save(PATH_CONFIG_USER)
	if err != OK :
		print( tr("Error while saving configuration file %s : %s ") % [PATH_CONFIG_USER , str(err)] )
	return err


func set_config_window_maximized(is_maximizer : bool) -> void:
	config_user.set_value(GRAPHICS_SECTION_NAME,MAXIMIZE_CONFIG_NAME, is_maximizer)


func set_config_window_fullscreen(is_fullscreen : bool) -> void:
	config_user.set_value(GRAPHICS_SECTION_NAME,FULLSCREEN_CONFIG_NAME, is_fullscreen)


func set_config_window_resolution(resolution : Vector2) -> void:
	config_user.set_value(GRAPHICS_SECTION_NAME,RESOLUTION_CONFIG_NAME, resolution)


func set_config_window_screen(screen : int) -> void:
	config_user.set_value(GRAPHICS_SECTION_NAME,SCREEN_CONFIG_NAME, screen)


func get_window_resolution_from_config() -> Vector2:
	return _get_window_resolution(config_user)


func set_config_locale(locale : String) -> void:
	config_user.set_value(LOCALE_SECTION_NAME, LOCALE_CONFIG_NAME, locale)


func reload_locale():
	var previous_locale = TranslationServer.get_locale()
	_load_locale(config_user)
	if previous_locale != TranslationServer.get_locale():
		emit_signal("locale_reloaded")


static func _get_api_config(config):
	var api_r = {}
	api_r.dns = config.api_dns
	api_r.port = config.api_port
	api_r.scheme = config.api_scheme
	api_r.ws_scheme = config.ws_scheme
	return api_r


static func _load_config_user(config):
	_load_all_key_bindings(config)
	_load_windows_settings(config)
	_load_audio_server_setting(config)
	_load_locale(config)


static func _load_locale(config):
	TranslationServer.set_locale(DEFAULT_LOCALE)
	if config.has_section_key(LOCALE_SECTION_NAME, LOCALE_CONFIG_NAME):
		var locale_to_load = config.get_value(LOCALE_SECTION_NAME, LOCALE_CONFIG_NAME)
		if TranslationServer.get_loaded_locales().has(locale_to_load):
			TranslationServer.set_locale(locale_to_load)


static func _load_audio_server_setting(config):
	for index_bus in range(AudioServer.bus_count):
		var name_bus = AudioServer.get_bus_name(index_bus).replace(" ", "_")
		if config.has_section_key(SOUND_SECTION_NAME, name_bus):
			var volume_linear = config.get_value(SOUND_SECTION_NAME, name_bus)
			var volume_db = linear2db(volume_linear) if volume_linear != 0 else Utils.AUDIO_VOLUME_DB_MIN
			AudioServer.set_bus_volume_db(index_bus, volume_db)


static func _load_windows_settings(config):
	OS.window_size = _get_window_resolution(config)
	if config.has_section_key(GRAPHICS_SECTION_NAME, SCREEN_CONFIG_NAME):
		# we need to chnage the screen before putting un full screen
		OS.current_screen = config.get_value(GRAPHICS_SECTION_NAME, SCREEN_CONFIG_NAME)
	if config.has_section_key(GRAPHICS_SECTION_NAME, MAXIMIZE_CONFIG_NAME):
		OS.window_maximized = config.get_value(GRAPHICS_SECTION_NAME, MAXIMIZE_CONFIG_NAME)
	if config.has_section_key(GRAPHICS_SECTION_NAME, FULLSCREEN_CONFIG_NAME):
		var full_screen = config.get_value(GRAPHICS_SECTION_NAME, FULLSCREEN_CONFIG_NAME)
		OS.window_fullscreen = full_screen
		if not full_screen:
			OS.center_window()
	else:
		OS.window_fullscreen = true


static func _get_window_resolution(config):
	var resolution = config.get_value(GRAPHICS_SECTION_NAME, RESOLUTION_CONFIG_NAME) if config.has_section_key(GRAPHICS_SECTION_NAME, RESOLUTION_CONFIG_NAME) else Vector2(1280, 720)
	resolution.x = max(resolution.x, 1280)
	resolution.y = max(resolution.y, 720)
	return resolution


static func _load_default_settings():
	OS.window_fullscreen = true
	TranslationServer.set_locale(DEFAULT_LOCALE)


static func _load_all_key_bindings(config):
	for action in ENABLE_KEY_BINDING_CHANGE:
		_load_key_binding(config, action)


static func _load_key_binding(config, action):
	if config.has_section_key(KEY_BINDING_SECTION_NAME, action):
		InputMap.action_erase_events(action)
		var events_input = config.get_value(KEY_BINDING_SECTION_NAME, action)
		for i in events_input.keys:
			var event = InputEventKey.new()
			event.scancode = i
			InputMap.action_add_event(action, event)
		for i in events_input.mouse:
			var event = InputEventMouseButton.new()
			event.button_index = i
			InputMap.action_add_event(action, event)
