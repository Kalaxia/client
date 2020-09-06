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


func _ready():
	_game_data.update_player_me()
	_game_data.selected_state.connect("system_selected", self, "_on_system_selected") # keep
	_game_data.connect("fleet_sailed", self, "_on_fleet_sailed") # keep
	Network.connect("CombatEnded", self, "_on_combat_ended")
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
	if event is InputEventMouseButton:
		_manage_input(event)
	elif event is InputEventMouseMotion:
		if _is_map_being_dragged:
			_move_camera( - event.get_relative() * $Camera2D.zoom)
			_camera_speed = event.speed


func _unhandled_input(event):
	# key events has not priority over gui
	if event is InputEventKey:
		_manage_input(event)


func _manage_input(event):
	if event is InputEventKey or event is InputEventMouseButton:
		if event.is_action_pressed("ui_move_map_left"):
			_motion_camera[Vector2.LEFT] = true
		elif event.is_action_released("ui_move_map_left"):
			_motion_camera[Vector2.LEFT] = false
		if event.is_action_pressed("ui_move_map_right"):
			_motion_camera[Vector2.RIGHT] = true
		elif event.is_action_released("ui_move_map_right"):
			_motion_camera[Vector2.RIGHT] = false
		if event.is_action_pressed("ui_move_map_up"):
			_motion_camera[Vector2.UP] = true
		elif event.is_action_released("ui_move_map_up"):
			_motion_camera[Vector2.UP] = false
		if event.is_action_pressed("ui_move_map_down"):
			_motion_camera[Vector2.DOWN] = true
		elif event.is_action_released("ui_move_map_down"):
			_motion_camera[Vector2.DOWN] = false
		if event.is_action_pressed("ui_map_center_system"):
			center_on_selected_system()
		if event.is_action_pressed("ui_zoom_in_map"):
			_zoom_camera(1.0 / _ZOOM_FACTOR)
		if event.is_action_pressed("ui_zoom_out_map"):
			_zoom_camera(_ZOOM_FACTOR)
		if event.is_action_pressed("ui_drag_map"):
			_is_map_being_dragged = true
		if event.is_action_released("ui_drag_map"):
			_is_map_being_dragged = false
		if event.is_action_pressed("ui_hud_scores"):
			$ParallaxBackground/HUD.show_scores()
		elif event.is_action_released("ui_hud_scores"):
			$ParallaxBackground/HUD.hide_scores()


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
	map.get_node(_game_data.selected_state.selected_system.id).select()


func _on_fleet_sailed(fleet, arrival_time):
	var sailing_fleet = MOVING_FLEET_SCENE.instance()
	sailing_fleet.set_name(fleet.id)
	var origin_system = map.get_node(fleet.system)
	origin_system.refresh()
	sailing_fleet.fleet = fleet
	sailing_fleet.arrival_time = arrival_time # todo is this necessary
	sailing_fleet.color = _game_data.get_player_color(_game_data.get_player(fleet.player)) # todo is this necessary
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
	for fleet in data.fleets.values():
		if fleet.destination_system != null:
			fleet_container.get_node(fleet.id).queue_free()
		elif fleet.ship_groups == null or fleet.ship_groups == []:
			_game_data.systems[fleet.system].erase_fleet_id(fleet.id)
		else:
			_game_data.get_fleet(fleet).set_ship_group_dict(fleet.ship_groups)
	map.get_node(data.system.id).refresh_fleet_pins()


func _on_player_income(data : Dictionary):
	_game_data.player.update_wallet(data.income)


# This method is called when the websocket notifies an another player's fleet creation
# It calls the same store method when the current player creates a new fleet
func _on_remote_fleet_created(fleet : Dictionary): # todo contaier
	_game_data.systems[fleet.system].add_fleet_dict(fleet)


# This method is called when the websocket notifies an another player's fleet sailing
# It notifies the store which call _on_fleet_sailed back
func _on_remote_fleet_sailed(fleet : Dictionary):
	var fleet_in_game_data : Fleet = _game_data.systems[fleet.system].fleet[fleet.id]
	fleet_in_game_data.update_fleet(fleet)
	_game_data.fleet_sail(fleet_in_game_data, fleet_in_game_data.destination_arrival_date)


func _on_fleet_arrival(fleet : Dictionary):
	_update_fleet_system(fleet)


func _on_system_conquerred(data : Dictionary):
	# todo
	var system : System = _game_data.get_system(data.system.id)
	system.erase_all_fleet()
	system.update(data.system)
	_update_fleet_system(data.fleet)
	map.get_node(data.system.id).refresh()
	if data.system.player == _game_data.player.id:
		_game_data.request_hangar(system)
	if _game_data.players[system.player].faction == _game_data.player.faction:
		_game_data.request_buildings(system)
	else:
		system.update_buildings([])
		system.update_hangar([])


func _update_fleet_system(fleet : Dictionary):
	_game_data.update_fleet_arrival(fleet)
	map.get_node(fleet.system).refresh_fleet_pins()
	if fleet_container.has_node(fleet.id):
		fleet_container.get_node(fleet.id).queue_free() # todo container ?


func _on_victory(data : Dictionary):
	# todo review
	Store.victorious_faction = data.victorious_faction
	_game_data.update_scores(data.scores)
	emit_signal("scene_requested", "scores")


func _on_faction_points_update(scores : Dictionary):
	_game_data.update_scores(scores)


func _on_ship_queue_finished(ship_data : Dictionary): # todo
	_game_data.get_system(ship_data.system).add_ship_group_to_hangar(ShipGroup.new(ship_data))


func _on_building_constructed(building : Dictionary): # todo
	_game_data.get_system(building.system).add_building_to_system(Building.new(building))


func _on_fleet_transfer(data : Dictionary):
	_game_data.systems[data.fleet.system].fleet[data.fleet.id].player = data.receiver_id
	if data.receiver_id == _game_data.player.id:
		Store.notify(
			tr("game.receive_fleet.title"),
			tr("game.receive_fleet.content %s") % Store.get_player(data.donator_id).username
		)
