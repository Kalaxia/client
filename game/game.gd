extends Node2D

signal scene_requested(scene)

const PARTICLE_AMMONT = 200.0
const LIMITS_MARGIN = 50
const _CAMERA_DRAG_COEFF = 4000.0
const _CAMERA_DRAG_COEFF_WHEN_DRAGGING = 40000.0
const _CAMERA_MOVE_KEY_AMOUNT = 600
const _ZOOM_FACTOR = 1.2
const _MIN_ZOOM_FACTOR = -15
const _MAX_ZOOM_FACTOR = 10
const _CAMERA_ZOOM_SPEED = 7.0
const SYSTEM_SCENE = preload("res://game/map/system.tscn")
const MOVING_FLEET_SCENE = preload("res://game/map/fleet_sailing.tscn")

var limits = [ 0, 0, 0, 0]
#left top right down
var _camera_speed = Vector2.ZERO
var _is_map_being_dragged = false
var _motion_camera = {
	Vector2.LEFT : false,
	Vector2.RIGHT : false,
	Vector2.UP : false,
	Vector2.DOWN : false,
}
var _game_data : GameData = Store.game_data

onready var camera2D = $Camera2D
onready var _target_zoom = camera2D.zoom
onready var particles_nodes = [
	$ParallaxBackground/ParallaxLayer1/Particles2D,
	$ParallaxBackground/ParallaxLayer2/Particles2D,
	$ParallaxBackground/ParallaxLayer3/Particles2D
]
onready var map = $ParallaxBackground/ParallaxLayer0/Map
onready var fleet_container = $ParallaxBackground/ParallaxLayer0/Map/FleetContainer
onready var background = $ParallaxBackground/Background
onready var hud = $ParallaxBackground/HUD
onready var event_capturer = $ParallaxBackground/ParallaxLayer0/EventCapturer
onready var sound_building = $ParallaxBackground/ParallaxLayer0/AudioParent/AudioStackingBuildingFinished
onready var sound_ship_queue = $ParallaxBackground/ParallaxLayer0/AudioParent/AudioStackingShipQueueFinished


func _ready():
	_game_data.update_player_me()
	_game_data.selected_state.connect("system_selected", self, "_on_system_selected")
	_game_data.connect("fleet_sailed", self, "_on_fleet_sailed")
	event_capturer.connect("gui_input", self, "_on_gui_input")
	Network.connect("BattleEnded", self, "_on_combat_ended")
	Network.connect("PlayerIncome", self, "_on_player_income")
	Network.connect("FleetCreated", self, "_on_remote_fleet_created")
	Network.connect("FleetSailed", self, "_on_remote_fleet_sailed")
	Network.connect("FleetArrived", self, "_on_fleet_arrival")
	Network.connect("SystemConquerred", self, "_on_system_conquerred")
	Network.connect("Victory", self, "_on_victory")
	Network.connect("FactionPointsUpdated", self, "_on_faction_points_update")
	Network.connect("ShipQueueFinished", self, "_on_ship_queue_finished")
	Network.connect("BuildingConstructed", self, "_on_building_constructed")
	Network.connect("PlayerMoneyTransfer", self, "_on_money_transfer")
	Network.connect("FleetTransfer", self, "_on_fleet_transfer")
	Network.connect("BattleStarted", self, "_on_battle_started")
	Network.connect("FleetJoinedBattle", self, "_on_fleet_joined_battle")
	Network.connect("conquestStarted", self, "_on_conquest_started")
	hud.connect("request_main_menu", self, "_on_request_main_menu")
	get_tree().get_root().connect("size_changed", self, "_on_resize_window")
	limits = draw_systems()
	camera2D.limit_left = (limits[0] - LIMITS_MARGIN - OS.get_window_size().x / 2.0) as int
	camera2D.limit_top = (limits[1] - LIMITS_MARGIN - OS.get_window_size().y / 2.0) as int
	camera2D.limit_right = (limits[2] + LIMITS_MARGIN + OS.get_window_size().x / 2.0) as int
	camera2D.limit_bottom = (limits[3] + LIMITS_MARGIN + OS.get_window_size().y / 2.0) as int
	_setup_particle()
	_set_background_ratio()
	# normaly by that point we have a systeme selected (see _ready of res://game/map/system.gd)
	center_on_selected_system()
	Store.notify(tr("game.notification.goal.title"), tr("game.notification.goal.content"))


func _process(delta):
	if not _is_map_being_dragged:
		var key_motion_camera_speed = Vector2.ZERO
		for directions in _motion_camera.keys():
			if  _motion_camera[directions]:
				key_motion_camera_speed -= directions * _CAMERA_MOVE_KEY_AMOUNT
		if key_motion_camera_speed != Vector2.ZERO:
			_camera_speed = key_motion_camera_speed /  camera2D.zoom
		if not _camera_speed.is_equal_approx(Vector2.ZERO):
			_move_camera(- _camera_speed * delta  *  camera2D.zoom)
	# the vector is reduces even when dragging such that if we stop moving the mouse
	# but the button is held down. When it is release the camara does not move arround
	if not _camera_speed.is_equal_approx(Vector2.ZERO):
		var sign_vector = _camera_speed.sign()
		var abs_vector = _camera_speed.abs()
		var coeff = _CAMERA_DRAG_COEFF_WHEN_DRAGGING if _is_map_being_dragged else _CAMERA_DRAG_COEFF
		abs_vector.x = max(abs_vector.x - coeff * delta * abs(_camera_speed.x) / _camera_speed.length(), 0.0)
		abs_vector.y = max(abs_vector.y - coeff * delta * abs(_camera_speed.y) / _camera_speed.length(), 0.0)
		_camera_speed = abs_vector * sign_vector
	if not _target_zoom.is_equal_approx(camera2D.zoom):
		var sign_vector = ( _target_zoom - camera2D.zoom).sign()
		var new_zoom = camera2D.zoom + Vector2(_CAMERA_ZOOM_SPEED,_CAMERA_ZOOM_SPEED) * delta * sign_vector
		new_zoom.x = min(new_zoom.x, _target_zoom.x) if sign_vector.x > 0 else max(new_zoom.x, _target_zoom.x)
		new_zoom.y = min(new_zoom.y, _target_zoom.y) if sign_vector.y > 0 else max(new_zoom.y, _target_zoom.y)
		camera2D.zoom = new_zoom


func _input(event):
	# mouse event has priority on the GUI
	if event is InputEventKey or event is InputEventMouseButton:
		if event.is_action_released("ui_move_map_left"):
			_motion_camera[Vector2.LEFT] = false
		if event.is_action_released("ui_move_map_right"):
			_motion_camera[Vector2.RIGHT] = false
		if event.is_action_released("ui_move_map_up"):
			_motion_camera[Vector2.UP] = false
		if event.is_action_released("ui_move_map_down"):
			_motion_camera[Vector2.DOWN] = false
		if event.is_action_released("ui_drag_map"):
			_is_map_being_dragged = false
	elif event is InputEventMouseMotion:
		if _is_map_being_dragged:
			_move_camera( - event.get_relative() * $Camera2D.zoom)
			_camera_speed = event.speed


func _unhandled_input(event):
	# key events has not priority over gui
	if event is InputEventKey or event is InputEventMouseButton:
		if event.is_action_pressed("ui_move_map_left"):
			_motion_camera[Vector2.LEFT] = true
		if event.is_action_pressed("ui_move_map_right"):
			_motion_camera[Vector2.RIGHT] = true
		if event.is_action_pressed("ui_move_map_up"):
			_motion_camera[Vector2.UP] = true
		if event.is_action_pressed("ui_move_map_down"):
			_motion_camera[Vector2.DOWN] = true
		if event.is_action("ui_map_center_system"):
			center_on_selected_system()


func _on_gui_input(event): # this is commong form a connection to event_capturer
	if event is InputEventKey or event is InputEventMouseButton:
		if event.is_action_pressed("ui_zoom_in_map"):
			_zoom_camera(1.0 / _ZOOM_FACTOR)
		if event.is_action_pressed("ui_zoom_out_map"):
			_zoom_camera(_ZOOM_FACTOR)
		if event.is_action_pressed("ui_drag_map"):
			_is_map_being_dragged = true


func draw_systems():
	var limits_systems = [ -1920, -1920, 1920, 1920 ]
	for i in _game_data.systems.keys():
		var system = SYSTEM_SCENE.instance()
		system.set_name(_game_data.systems[i].id)
		system.system = _game_data.systems[i]
		map.add_child(system)
		limits_systems[0] = min(Utils.SCALE_SYSTEMS_COORDS * _game_data.systems[i].coordinates.x, limits_systems[0])
		limits_systems[1] = min(Utils.SCALE_SYSTEMS_COORDS * _game_data.systems[i].coordinates.y, limits_systems[1])
		limits_systems[2] = max(Utils.SCALE_SYSTEMS_COORDS * _game_data.systems[i].coordinates.x, limits_systems[2])
		limits_systems[3] = max(Utils.SCALE_SYSTEMS_COORDS * _game_data.systems[i].coordinates.y, limits_systems[3])
	return limits_systems


func center_on_selected_system():
	if _game_data.selected_state.selected_system != null:
		var coordinates_selected = _game_data.selected_state.selected_system.coordinates
		_set_camera_position(Vector2(Utils.SCALE_SYSTEMS_COORDS, Utils.SCALE_SYSTEMS_COORDS) * coordinates_selected)
		_camera_speed = Vector2.ZERO


func _setup_particle():
	var material_part = particles_nodes[0].get("process_material")
	var x_extend_particule = max(- limits[0], limits[2]) + LIMITS_MARGIN + OS.get_window_size().x / 2.0
	var y_extend_particule = max(- limits[1], limits[3]) + LIMITS_MARGIN + OS.get_window_size().y / 2.0
	material_part.emission_box_extents.x = x_extend_particule
	material_part.emission_box_extents.y = y_extend_particule
	var particle_ammont = x_extend_particule * y_extend_particule / (1280 * 720) * PARTICLE_AMMONT as int
	var rect_visibility = Rect2(
			limits[0] - LIMITS_MARGIN - OS.get_window_size().x / 2.0,
			limits[1] - LIMITS_MARGIN - OS.get_window_size().y / 2.0,
			limits[2] - limits[0] + 2.0 * LIMITS_MARGIN + OS.get_window_size().x,
			limits[3] - limits[1] + 2.0 * LIMITS_MARGIN + OS.get_window_size().y
	)
	for particles_node in particles_nodes:
		particles_node.amount = particle_ammont
		particles_node.visibility_rect = rect_visibility


func _on_resize_window():
	_set_background_ratio()


func _set_background_ratio():
	background.set_scale(OS.get_window_size() / Vector2(1920.0, 1080.0))


func _on_system_selected(old_system):
	if old_system != null and map.has_node(old_system.id):
		map.get_node(old_system.id).unselect()
	if map.has_node(_game_data.selected_state.selected_system.id):
		map.get_node(_game_data.selected_state.selected_system.id).select()


func _on_fleet_sailed(fleet):
	var sailing_fleet = MOVING_FLEET_SCENE.instance()
	sailing_fleet.set_name(fleet.id)
	var origin_system = map.get_node(fleet.system)
	origin_system.refresh()
	sailing_fleet.fleet = fleet
	sailing_fleet.origin_position = origin_system.get_position()
	sailing_fleet.destination_position = map.get_node(fleet.destination_system).get_position()
	fleet_container.add_child(sailing_fleet)


func _zoom_camera(factor):
	var max_screen_size = Vector2(camera2D.limit_right - camera2D.limit_left, camera2D.limit_bottom - camera2D.limit_top)
	var max_zoom_factor_fit = floor(min(log(max_screen_size.x / OS.window_size.x), \
			log(max_screen_size.y / OS.window_size.y)) / log(_ZOOM_FACTOR))
	_target_zoom.x = clamp(camera2D.zoom.x * factor, pow(_ZOOM_FACTOR, _MIN_ZOOM_FACTOR), \
			pow(_ZOOM_FACTOR, min(_MAX_ZOOM_FACTOR, max_zoom_factor_fit)))
	_target_zoom.y = clamp(camera2D.zoom.y * factor, pow(_ZOOM_FACTOR, _MIN_ZOOM_FACTOR), \
			pow(_ZOOM_FACTOR, min(_MAX_ZOOM_FACTOR, max_zoom_factor_fit)))


func _move_camera(vector):
	_set_camera_position(camera2D.position + vector)


func _set_camera_position(position_camera_set):
	# this verify that the camera is within the limits.
	# godot's camera limits the view inside the limits closest to the camera position
	# this means that the camera position cal go out of bounds,
	# this is however inuititiev when draggind the camera
	# call this function instand of camera2D.position.
	var new_position = position_camera_set
	new_position.x = max(min(new_position.x, camera2D.limit_right - OS.get_window_size().x / 2.0 * camera2D.zoom.x), \
			camera2D.limit_left + OS.get_window_size().x / 2.0 * camera2D.zoom.x)
	new_position.y = max(min(new_position.y, camera2D.limit_bottom - OS.get_window_size().y / 2.0 * camera2D.zoom.y), \
			camera2D.limit_top + OS.get_window_size().y / 2.0 * camera2D.zoom.y)
	camera2D.position = new_position


func _on_request_main_menu():
	emit_signal("scene_requested", "menu")


########## Network ##########


func _on_money_transfer(data : Dictionary):
	_game_data.player.update_wallet(data.amount)
	var username = _game_data.get_player(data.player_id).username
	Store.notify(
		tr("game.receive_credits_notif.title"), 
		tr("game.receive_credits_notif.content %s %d") % [username, data.amount]
	)


func _on_combat_ended(data : Dictionary):
	for faction in data.fleets.values():
		for fleet in faction.values():
			if fleet_container.has_node(fleet.id):
				# maybe it is not necessary anymore
				fleet_container.get_node(fleet.id).queue_free()
			var fleet_game_data = _game_data.get_fleet(fleet)
			fleet_game_data.set_squadrons_dict(fleet.squadrons)
			if fleet_game_data.is_destroyed():
				_game_data.systems[fleet.system].erase_fleet_id(fleet.id)
	map.get_node(data.system).refresh_fleet_pins()


func _on_player_income(data : Dictionary):
	_game_data.player.update_wallet(data.income)


# This method is called when the websocket notifies an another player's fleet creation
# It calls the same store method when the current player creates a new fleet
func _on_remote_fleet_created(fleet : Dictionary):
	_game_data.systems[fleet.system].add_fleet_dict(fleet)


# This method is called when the websocket notifies an another player's fleet sailing
# It notifies the store which call _on_fleet_sailed back
func _on_remote_fleet_sailed(fleet : Dictionary):
	var fleet_in_game_data : Fleet = _game_data.systems[fleet.system].fleets[fleet.id]
	fleet_in_game_data.update_fleet(fleet)
	_game_data.fleet_sail(fleet_in_game_data)


func _on_fleet_arrival(fleet : Dictionary):
	_update_fleet_system_arrival(fleet)


func _on_system_conquerred(data : Dictionary):
	# todo check selected fleet existance 
	var system = _game_data.get_system(data.system.id)
	system.update(data.system)
	if data.has("fleets"):
		for faction in data.fleets.values():
			for fleet_dict in faction.values():
				_update_fleet_system_arrival(fleet_dict)
	elif data.has("fleet"):
		_update_fleet_system_arrival(data.fleet)
	for fleet_system in system.fleets:
		var is_fleet_destroyed = true
		if data.has("fleets"):
			for faction in data.fleets.values():
				for fleet_dict in faction.values():
					if fleet_dict.id == fleet_system:
						is_fleet_destroyed = _game_data.get_fleet(fleet_dict).is_destroyed()
		elif data.has("fleet"):
			if data.fleet.id == fleet_system:
				is_fleet_destroyed = _game_data.get_fleet(data.fleet).is_destroyed()
		if is_fleet_destroyed:
			system.erase_fleet_id(fleet_system)
	if data.system.player == _game_data.player.id:
		_game_data.request_hangar(system)
		_game_data.request_ship_queues(system)
	if _game_data.players[system.player].faction == _game_data.player.faction:
		_game_data.request_buildings(system)
	else:
		system.set_buildings([])
		system.set_hangar([])
		system.ship_queues = []
	system.on_conquerred()
	map.get_node(data.system.id).refresh() # todo container


func _update_fleet_system_arrival(fleet : Dictionary):
	_game_data.update_fleet_arrival(fleet)
	map.get_node(fleet.system).refresh_fleet_pins()
	if fleet_container.has_node(fleet.id):
		fleet_container.get_node(fleet.id).queue_free() # todo container ?


func _on_victory(data : Dictionary):
	Store.victorious_faction = data.victorious_faction
	_game_data.update_scores(data.scores)
	emit_signal("scene_requested", "scores")


func _on_faction_points_update(scores : Dictionary):
	_game_data.update_scores(scores)


func _on_ship_queue_finished(ship_data : Dictionary):
	var ship_group = Squadron.new(ship_data)
	_game_data.get_system(ship_data.system).queue_finished(ship_group)
	Audio.ship_queue_finished_audio(ship_group)


func _on_building_constructed(building : Dictionary):
	var system = _game_data.get_system(building.system)
	system.building_contructed(Building.new(building))


func _on_fleet_transfer(data : Dictionary):
	_game_data.systems[data.fleet.system].fleets[data.fleet.id].player = data.receiver_id
	if data.receiver_id == _game_data.player.id:
		Store.notify(
			tr("game.receive_fleet.title"),
			tr("game.receive_fleet.content %s") % _game_data.get_player(data.donator_id).username
		)


func _on_battle_started(data : Dictionary):
	for faction in data.fleets.values():
		for fleet in faction.values():
			if _game_data.is_fleet_sailing(fleet):
				_update_fleet_system_arrival(fleet)
			var fleet_game_data = _game_data.get_fleet(fleet)
			if fleet_game_data != null:
				fleet_game_data.set_squadrons_dict(fleet.squadrons)
	map.get_node(data.system).refresh_fleet_pins()


func _on_fleet_joined_battle(fleet : Dictionary):
	_update_fleet_system_arrival(fleet)


func _on_conquest_started(data : Dictionary):
	_update_fleet_system_arrival(data.fleet)
	var system = _game_data.get_system(data.system)
	system.conquest_started_at = data.started_at
	system.conquest_ended_at = data.ended_at
	map.get_node(data.system).refresh_fleet_pins()
