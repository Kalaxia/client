extends Node

const ENV = "development"

var api = {
	'dns': null,
	'port': null,
	'scheme': null,
	'ws_scheme': null
}

var config
const PATH_CONFIG = "res://config/" + ENV + ".cfg"
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
]
const KEY_BINDING_SECTION_NAME = "key binding"

func _ready():
	config = ConfigFile.new()
	var err = config.load(PATH_CONFIG)
	if err == OK:
		api.dns = config.get_value('network', 'api_dns', '127.0.0.1')
		api.port = config.get_value('network', 'api_port', 8080)
		api.scheme = config.get_value('network', 'api_scheme', 'http')
		api.ws_scheme = config.get_value('network', 'ws_scheme', 'ws')
		
		for action in ENABLE_KEY_BINDING_CHANGE:
			if config.has_section_key(KEY_BINDING_SECTION_NAME,action):
				InputMap.action_erase_events(action)
				var events_input = config.get_value(KEY_BINDING_SECTION_NAME,action)
				for i in events_input.keys:
					var event = InputEventKey.new()
					event.scancode = i
					InputMap.action_add_event(action,event)
				for i in events_input.mouse:
					var event = InputEventMouseButton.new()
					event.button_mask = i
					InputMap.action_add_event(action,event)
	else:
		print("error while parsing configuration file : " + str(err))

func save_key_binding(action):
	var events_to_save = {"keys": [] ,"mouse":[]}
	for event in InputMap.get_action_list(action):
		if event is InputEventKey:
			events_to_save.keys.push_back(event.scancode)
		elif event is InputEventMouseButton:
			events_to_save.mouse.push_back(event.button_mask)
	config.set_value(KEY_BINDING_SECTION_NAME,action,events_to_save)
	var err = config.save(PATH_CONFIG)
	if err != OK :
		print("Error while saving the config : " + str(err))
