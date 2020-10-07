extends Control

signal ressource_loaded(ressource_name, ressource)
signal finished()
signal scene_requested(scene) # not used used finished instead

enum STATE_NETWORK_ELEMENT {
	WAIT,
	OK,
	ERROR,
}

const GREEN = Color(50.0 / 255.0, 191.0 / 255.0, 87.0 / 255.0)
const RED = Color(191.0 / 255.0, 62.0 / 255.0, 50.0 / 255.0)
const ORANGE = Color(214.0 / 255.0, 150.0 / 255.0, 0.0)

onready var assets : KalaxiaAssets = load("res://resources/assets.tres")
var loaded_factions = 0
var loaded_ship_models = 0
var load_queue = {} setget set_load_queue
var queue_finished = false
var loader = null
var current_load_element = null
var has_emited_finished = false
var _number_of_element_to_load = 0
var _current_loading_component_load = 0
var cached_data : CachedResource

onready var global_progressbar = $Foreground/MarginContainer/VBoxContainer/ressources/ressourceLoading/GlobalProgress
onready var ressource_progressbar = $Foreground/MarginContainer/VBoxContainer/ressources/ressourceLoading/ProgressBar
onready var loading_componenet_label = $Foreground/MarginContainer/VBoxContainer/ressources/ressourceLoading/LoadingComponenet
onready var label_network_status = $Foreground/MarginContainer/VBoxContainer/Network/VBoxContainer/HBoxContainer/ContainerAuth/LabelAuth
onready var label_faction_status = $Foreground/MarginContainer/VBoxContainer/Network/VBoxContainer/HBoxContainer/ContainerFaction/LabelFaction
onready var timer_auth = $TimerAuth
onready var quit_button = $Foreground/MarginContainer/VBoxContainer/VBoxContainer/QuitButton
onready var label_loading_error = $Foreground/MarginContainer/VBoxContainer/ressources/ressourceLoading/LoadingError
onready var timer_res = $TimerRessource
onready var label_constant_status = $Foreground/MarginContainer/VBoxContainer/Network/VBoxContainer/HBoxContainer/ContainerConstantes/LabelConstante
onready var label_ship_status = $Foreground/MarginContainer/VBoxContainer/Network/VBoxContainer/HBoxContainer/ContainerShips/LabelShips
onready var label_building_status = $Foreground/MarginContainer/VBoxContainer/Network/VBoxContainer/HBoxContainer/ContainerBuiilding/LabelBuilding
onready var version_label = $Foreground/MarginContainer/VBoxContainer/VersionLabel


func _ready():
	version_label.text = tr("global.loading.version %s") % Config.VERSION.version
	cached_data = load(CachedResource.CACHED_DATA_PATH)
	if not cached_data:
		cached_data = CachedResource.new()
	quit_button.visible = false
	if Network.token == null:
		Network.connect_to_host()
		Network.connect("authenticated", self, "_on_authentication")
	else:
		set_state_label(STATE_NETWORK_ELEMENT.OK, label_network_status)
	if cached_data.refresh(null):
		cached_data.connect("loaded", self, "_on_resource_loaded")
		cached_data.connect("error", self, "_on_resource_loading_error")
	else:
		set_state_label(STATE_NETWORK_ELEMENT.OK, label_faction_status)
		set_state_label(STATE_NETWORK_ELEMENT.OK, label_constant_status)
		set_state_label(STATE_NETWORK_ELEMENT.OK, label_ship_status)
		set_state_label(STATE_NETWORK_ELEMENT.OK, label_building_status)
	Store.connect("notification_added",self,"_on_notification_added")
	timer_auth.connect("timeout", self, "_on_timeout_auth")
	timer_res.connect("timeout", self, "_on_timeout_res")
	# if we wait too much and there is no queue of element to load we want to quit
	quit_button.connect("pressed", self, "_on_press_quit")


func _on_timeout_res():
	queue_finished = queue_finished or load_queue.size() == 0 # if the queue is empty we set that we have finished
	verify_is_finished()


func _on_press_quit():
	get_tree().quit()


func set_state_label(state, node):
	match state:
		STATE_NETWORK_ELEMENT.OK:
			node.add_color_override("font_color", GREEN)
			node.text = tr("global.loading.ok")
		STATE_NETWORK_ELEMENT.WAIT:
			node.add_color_override("font_color", ORANGE)
			node.text = tr("global.loading.waiting")
		STATE_NETWORK_ELEMENT.ERROR:
			node.add_color_override("font_color", RED)
			node.text = tr("global.loading.error")
		


func _on_notification_added(notif):
	if notif.title == tr("error.connexion_impossible") or notif.title == tr("error.http_not_connected") or notif.title == tr("error.network_error"):
		set_state_label(STATE_NETWORK_ELEMENT.ERROR, label_network_status)
		set_state_label(STATE_NETWORK_ELEMENT.ERROR, label_faction_status)
		set_state_label(STATE_NETWORK_ELEMENT.ERROR, label_constant_status)
		set_state_label(STATE_NETWORK_ELEMENT.ERROR, label_ship_status)
		set_state_label(STATE_NETWORK_ELEMENT.ERROR, label_building_status)
		quit_button.visible = true


func _on_timeout_auth():
	if Network.token == null: 
		set_state_label(STATE_NETWORK_ELEMENT.ERROR, label_network_status)
		quit_button.visible = true
	if not cached_data.dict_loaded[CachedResource.Resource_elements.FACTIONS]:
		set_state_label(STATE_NETWORK_ELEMENT.ERROR, label_faction_status)
		quit_button.visible = true
	if not cached_data.dict_loaded[CachedResource.Resource_elements.SHIP_MODELS]:
		set_state_label(STATE_NETWORK_ELEMENT.ERROR, label_ship_status)
		quit_button.visible = true
	if not cached_data.dict_loaded[CachedResource.Resource_elements.CONSTANTS]:
		set_state_label(STATE_NETWORK_ELEMENT.ERROR, label_constant_status)
		quit_button.visible = true
	if not cached_data.dict_loaded[CachedResource.Resource_elements.BUILDING]:
		set_state_label(STATE_NETWORK_ELEMENT.ERROR, label_building_status)
		quit_button.visible = true


func _on_resource_loaded(res_name):
	set_state_label(STATE_NETWORK_ELEMENT.OK, {
		CachedResource.Resource_elements.BUILDING: label_building_status,
		CachedResource.Resource_elements.SHIP_MODELS: label_ship_status,
		CachedResource.Resource_elements.FACTIONS: label_faction_status,
		CachedResource.Resource_elements.CONSTANTS: label_constant_status,
	}[res_name])
	verify_is_finished()


func _on_resource_loading_error(res_name, err, response_code, body):
	set_state_label(STATE_NETWORK_ELEMENT.ERROR, {
		CachedResource.Resource_elements.BUILDING: label_building_status,
		CachedResource.Resource_elements.SHIP_MODELS: label_ship_status,
		CachedResource.Resource_elements.FACTIONS: label_faction_status,
		CachedResource.Resource_elements.CONSTANTS: label_constant_status,
	}[res_name])
	verify_is_finished()


func _on_authentication():
	label_network_status.add_color_override("font_color", GREEN)
	label_network_status.text = tr("global.loading.ok")
	verify_is_finished()


func set_load_queue(load_queue_param):
	_current_loading_component_load = 0
	has_emited_finished = false
	load_queue = load_queue_param
	for i in load_queue.values():
		if i.scene == null:
			_number_of_element_to_load += 1 
	update_progress()
	queue_finished = _number_of_element_to_load == 0
	if queue_finished:
		verify_is_finished()
	else:
		set_process(true)


func verify_is_finished():
	if queue_finished \
			and Network.token != null \
			and cached_data.has_finished_loading() \
			and not has_emited_finished:
		Store.update_assets(cached_data)	
		has_emited_finished = true
		emit_signal("finished")


func _process(delta):
	if loader == null or current_load_element == null:
		current_load_element = null
		var keys = load_queue.keys()
		for i in keys:
			if load_queue[i].scene == null:
				current_load_element = i
				_current_loading_component_load += 1
				update_global_progress()
				break
		if current_load_element != null:
			loader = ResourceLoader.load_interactive(load_queue[current_load_element].path)
		else:
			queue_finished = keys.size() > 0 # we only set as finished if the queue has element, we have a timer for mark as finished if the queue is emtpy
			# however this menu is not meant to be shown if there is no elements to load
			verify_is_finished()
			set_process(false)
			return
	# poll your loader
	var err = loader.poll()
	if err == ERR_FILE_EOF: # Finished loading.
		var resource = loader.get_resource()
		load_queue[current_load_element].scene = resource
		emit_signal("ressource_loaded", current_load_element, resource)
		loader = null
		current_load_element = null
		update_progress()
	elif err == OK:
		pass
	else: # error during loading
		quit_button.visible = true
		label_loading_error.text += (tr("global.loading.ressource.error %s %d") % [tr("global.loading.ressource." + current_load_element) ,err]) + "\n"
		set_process(false)
		loader = null
		current_load_element = null
	update_progress()


func update_progress():
	if loader!= null :
		ressource_progressbar.max_value = loader.get_stage_count()
		ressource_progressbar.value = loader.get_stage()
		ressource_progressbar.get_node("Label").text = tr("global.loading.progressbar_ressource %d %d") % [loader.get_stage(), loader.get_stage_count()]
	else: 
		ressource_progressbar.value = ressource_progressbar.max_value 
		ressource_progressbar.get_node("Label").text = tr("global.loading.progressbar_ressource %d %d") % [ressource_progressbar.max_value, ressource_progressbar.max_value]


func update_global_progress():
	loading_componenet_label.text = tr("global.loading.ressource." + current_load_element) if current_load_element != null else tr("global.loading.none_loading")
	global_progressbar.max_value = _number_of_element_to_load
	global_progressbar.value = _current_loading_component_load
	global_progressbar.get_node("Label").text = tr("global.loading.progressbar_global %d %d") % [_current_loading_component_load, _number_of_element_to_load]
