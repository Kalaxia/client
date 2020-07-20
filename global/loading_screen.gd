extends Control

const GREEN = Color(50.0 / 255.0, 191.0 / 255.0, 87.0/ 255.0)
const RED = Color(191.0 / 255.0, 62.0 / 255.0, 50.0/ 255.0)

var load_queue = {} setget set_load_queue
var queue_finished = false
var loader = null
var current_load_element = null
var time_max = 1000.0 / 60.0

var has_emited_finished = false

var _number_of_element_to_load = 0
var _current_loading_component_load = 0

onready var global_progressbar = $MarginContainer/VBoxContainer/ressources/ressourceLoading/GlobalProgress
onready var ressource_progressbar = $MarginContainer/VBoxContainer/ressources/ressourceLoading/ProgressBar
onready var loading_componenet_label = $MarginContainer/VBoxContainer/ressources/ressourceLoading/LoadingComponenet
onready var label_network_status = $MarginContainer/VBoxContainer/Network/VBoxContainer/HBoxContainer/LabelAuth
onready var label_faction_status = $MarginContainer/VBoxContainer/Network/VBoxContainer/HBoxContainer/LabelFaction

signal ressource_loaded(ressource_name, ressource)
signal finished()
signal scene_requested(scene) # not used used finished instead

func _ready():
	if Network.token == null:
		Network.connect_to_host()
		Network.connect("authenticated", self, "_on_authentication")
	else:
		label_network_status.add_color_override("font_color", GREEN)
		label_network_status.text = tr("global.loading.ok")
	if Store._state.factions.size() == 0:
		Network.req(self, "_on_factions_loaded", "/api/factions/")
	else:
		label_faction_status.add_color_override("font_color", GREEN)
		label_faction_status.text = tr("global.loading.ok")
	Store.connect("notification_added",self,"_on_notification_added")

func _on_notification_added(notif):
	print(notif)
	if notif.title == tr("error.connexion_impossible") or notif.title == tr("error.http_not_connected") or notif.title == tr("error.network_error"):
		label_network_status.add_color_override("font_color", RED)
		label_network_status.text = tr("global.loading.error")
		label_faction_status.add_color_override("font_color", RED)
		label_faction_status.text = tr("global.loading.error")

func _on_factions_loaded(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
	var factions = JSON.parse(body.get_string_from_utf8()).result
	if factions != null:
		Store.set_factions(factions)
		label_faction_status.add_color_override("font_color", GREEN)
		label_faction_status.text = tr("global.loading.ok")
	else:
		label_faction_status.add_color_override("font_color", RED)
		label_faction_status.text = tr("global.loading.error")
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
	if Store._state.factions.size() > 0 and queue_finished and Network.token != null and not has_emited_finished:
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
			queue_finished = true
			verify_is_finished()
			set_process(false)
			return
	var t = OS.get_ticks_msec()
	while OS.get_ticks_msec() < t + time_max: # use "time_max" to control for how long we block this thread
 # poll your loader
		var err = loader.poll()
		if err == ERR_FILE_EOF: # Finished loading.
			var resource = loader.get_resource()
			load_queue[current_load_element].scene = resource
			emit_signal("ressource_loaded", current_load_element, resource)
			loader = null
			current_load_element = null
			update_progress()
			break
		elif err == OK:
			pass
		else: # error during loading
			loader = null
			current_load_element = null
			break
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
