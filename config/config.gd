extends Node

const ENV = "development"

var api = {
	'dns': null,
	'port': null,
	'scheme': null,
	'ws_scheme': null
}

var config_network = ConfigFile.new()
var config_user = ConfigFile.new()
const PATH_CONFIG_NETWORK = "res://config/" + ENV + ".cfg"
const PATH_CONFIG_USER = "res://config/config.cfg"

const ENABLE_KEY_BINDING_CHANGE = [
	"ui_zoom_out_map",
	"ui_zoom_in_map",
	"ui_drag_map",
	"ui_move_map_up",
	"ui_move_map_down",
	"ui_move_map_left",
	"ui_move_map_right",
	"ui_add_fleet",
	"ui_add_ships",
	"ui_map_center_system",
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

signal reload_locale()

func _ready():
	config_network = ConfigFile.new()
	var err = config_network.load(PATH_CONFIG_NETWORK)
	if err == OK:
		api.dns = config_network.get_value('network', 'api_dns', '127.0.0.1')
		api.port = config_network.get_value('network', 'api_port', 8080)
		api.scheme = config_network.get_value('network', 'api_scheme', 'http')
		api.ws_scheme = config_network.get_value('network', 'ws_scheme', 'ws')
	else:
		print("error while parsing configuration file "+PATH_CONFIG_NETWORK+" : " + str(err))
	var err_config_user = config_user.load(PATH_CONFIG_USER)
	if err_config_user == OK:
		for action in ENABLE_KEY_BINDING_CHANGE:
			if config_user.has_section_key(KEY_BINDING_SECTION_NAME,action):
				InputMap.action_erase_events(action)
				var events_input = config_user.get_value(KEY_BINDING_SECTION_NAME,action)
				for i in events_input.keys:
					var event = InputEventKey.new()
					event.scancode = i
					InputMap.action_add_event(action,event)
				for i in events_input.mouse:
					var event = InputEventMouseButton.new()
					event.button_index = i
					InputMap.action_add_event(action,event)
		for index_bus in range(AudioServer.bus_count):
			var name_bus = AudioServer.get_bus_name(index_bus).replace(" ","_")
			if config_user.has_section_key(SOUND_SECTION_NAME,name_bus):
				var volume_linear = config_user.get_value(SOUND_SECTION_NAME,name_bus)
				var volume_db = linear2db(volume_linear) if volume_linear!= 0 else Utils.AUDIO_VOLUME_DB_MIN
				AudioServer.set_bus_volume_db(index_bus,volume_db)
		OS.window_size = get_window_resolution_from_config()
		if config_user.has_section_key(GRAPHICS_SECTION_NAME,SCREEN_CONFIG_NAME):
			# we need to chnage the screen before putting un full screen
			OS.current_screen = config_user.get_value(GRAPHICS_SECTION_NAME,SCREEN_CONFIG_NAME)
		if config_user.has_section_key(GRAPHICS_SECTION_NAME,MAXIMIZE_CONFIG_NAME):
			OS.window_maximized = config_user.get_value(GRAPHICS_SECTION_NAME,MAXIMIZE_CONFIG_NAME)
		if config_user.has_section_key(GRAPHICS_SECTION_NAME,FULLSCREEN_CONFIG_NAME):
			OS.window_fullscreen = config_user.get_value(GRAPHICS_SECTION_NAME,FULLSCREEN_CONFIG_NAME)
		else:
			OS.window_fullscreen = true
		load_locale()
		
	else:
		print( tr("error while parsing configuration file %s : %s ") % [ PATH_CONFIG_USER, str(err)] )
		# by default we try to borerless maximize
		OS.window_fullscreen = true
		TranslationServer.set_locale(DEFAULT_LOCALE)

func save_key_binding(action : String):
	var events_to_save = {"keys": [] ,"mouse": []}
	for event in InputMap.get_action_list(action):
		if event is InputEventKey:
			events_to_save.keys.push_back(event.scancode)
		elif event is InputEventMouseButton:
			events_to_save.mouse.push_back(event.button_index)
	config_user.set_value(KEY_BINDING_SECTION_NAME,action,events_to_save)

func save_audio_volume(bus_name: String,linear_volume : float) -> void:
	config_user.set_value(SOUND_SECTION_NAME,bus_name.replace(" ","_"),linear_volume)

func save_config_file():
	var err = config_user.save(PATH_CONFIG_USER)
	if err != OK :
		print( tr("Error while saving configuration file %s : %s ") % [PATH_CONFIG_USER , str(err)] )
	return err

func set_config_window_maximized(is_maximizer : bool) -> void:
	config_user.set_value(GRAPHICS_SECTION_NAME,MAXIMIZE_CONFIG_NAME,is_maximizer)

func set_config_window_fullscreen(is_fullscreen : bool) -> void:
	config_user.set_value(GRAPHICS_SECTION_NAME,FULLSCREEN_CONFIG_NAME,is_fullscreen)
	
func set_config_window_resolution(resolution : Vector2) -> void:
	config_user.set_value(GRAPHICS_SECTION_NAME,RESOLUTION_CONFIG_NAME,resolution)
	
func set_config_window_screen(screen : int) -> void:
	config_user.set_value(GRAPHICS_SECTION_NAME,SCREEN_CONFIG_NAME,screen)

func get_window_resolution_from_config() -> Vector2:
	var resolution = config_user.get_value(GRAPHICS_SECTION_NAME,RESOLUTION_CONFIG_NAME) if config_user.has_section_key(GRAPHICS_SECTION_NAME,RESOLUTION_CONFIG_NAME) else Vector2(1280,720)
	resolution.x = max(resolution.x,1280)
	resolution.y = max(resolution.y,720)
	return resolution

func set_config_locale(locale : String) -> void:
	config_user.set_value(LOCALE_SECTION_NAME,LOCALE_CONFIG_NAME,locale)

func load_locale():
	TranslationServer.set_locale(DEFAULT_LOCALE)
	if config_user.has_section_key(LOCALE_SECTION_NAME,LOCALE_CONFIG_NAME):
		var locale_to_load = config_user.get_value(LOCALE_SECTION_NAME,LOCALE_CONFIG_NAME)
		if TranslationServer.get_loaded_locales().has(locale_to_load):
			TranslationServer.set_locale(locale_to_load)

func reload_locale():
	var previous_locale = TranslationServer.get_locale()
	load_locale()
	if previous_locale != TranslationServer.get_locale():
		emit_signal("reload_locale")
