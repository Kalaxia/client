extends Node2D

signal scene_requested(scene)

var system_scene = preload("res://game/map/system.tscn")
var moving_fleet_scene = preload("res://game/map/fleet_sailing.tscn")
var _camera_speed = Vector2.ZERO
var _is_map_being_dragged = false
var limits = [ 0, 0, 0, 0]
#left top right down

const PARTICLE_AMMONT = 200.0
const LIMITS_MARGIN = 50
const CAMERA_DRAG_COEFF = 4000.0
const CAMERA_DRAG_COEFF_WHEN_DRAGGING = 40000.0
const CAMERA_MOVE_KEY_AMOUNT = 600
const _ZOOM_FACTOR = 1.2
const _MIN_ZOOM_FACTOR = -15
const _MAX_ZOOM_FACTOR = 10
var _motion_camera = {
		Vector2.LEFT : false,
		Vector2.RIGHT : false,
		Vector2.UP : false,
		Vector2.DOWN : false
	}

func _ready():
	Store.connect("system_selected", self, "_on_system_selected")
	Store.connect("fleet_created", self, "_on_fleet_created")
	Store.connect("fleet_sailed", self, "_on_fleet_sailed")
	Network.connect("CombatEnded", self, "_on_combat_ended")
	Network.connect("PlayerIncome", self, "_on_player_income")
	Network.connect("FleetCreated", self, "_on_remote_fleet_created")
	Network.connect("FleetSailed", self, "_on_remote_fleet_sailed")
	Network.connect("FleetArrived", self, "_on_fleet_arrival")
	Network.connect("SystemConquerred", self, "_on_system_conquerred")
	Network.connect("Victory", self, "_on_victory")
	get_tree().get_root().connect("size_changed", self, "_on_resize_window")
	limits = draw_systems()
	$Camera2D.limit_left = (limits[0] - LIMITS_MARGIN - OS.get_window_size().x /2) as int
	$Camera2D.limit_top = (limits[1] - LIMITS_MARGIN - OS.get_window_size().y /2) as int
	$Camera2D.limit_right = (limits[2] + LIMITS_MARGIN + OS.get_window_size().x /2) as int
	$Camera2D.limit_bottom = (limits[3] + LIMITS_MARGIN + OS.get_window_size().y /2) as int
	var rect_visibility = Rect2(limits[0] - LIMITS_MARGIN - OS.get_window_size().x / 2.0, limits[1] - LIMITS_MARGIN - OS.get_window_size().y / 2.0, limits[2]-limits[0] + 2.0 * LIMITS_MARGIN + OS.get_window_size().x, limits[3]-limits[1] + 2.0 * LIMITS_MARGIN + OS.get_window_size().y)
	$ParallaxBackground/ParallaxLayer1/Particles2D.visibility_rect = rect_visibility
	$ParallaxBackground/ParallaxLayer2/Particles2D.visibility_rect = rect_visibility
	$ParallaxBackground/ParallaxLayer3/Particles2D.visibility_rect = rect_visibility
	var material_part = $ParallaxBackground/ParallaxLayer3/Particles2D.get("process_material")
	var x_extend_particule = max(-limits[0],limits[2]) + LIMITS_MARGIN + OS.get_window_size().x /2
	var y_extend_particule = max(-limits[1],limits[3]) + LIMITS_MARGIN + OS.get_window_size().y /2
	material_part.emission_box_extents.x = x_extend_particule
	material_part.emission_box_extents.y = y_extend_particule
	var particle_ammont = x_extend_particule * y_extend_particule / (1280 * 720 ) * PARTICLE_AMMONT as int
	$ParallaxBackground/ParallaxLayer1/Particles2D.amount = particle_ammont
	$ParallaxBackground/ParallaxLayer2/Particles2D.amount = particle_ammont
	$ParallaxBackground/ParallaxLayer3/Particles2D.amount = particle_ammont
	_set_background_ratio()

func _on_resize_window():
	_set_background_ratio()

func _set_background_ratio():
	$ParallaxBackground/Background.set_scale(OS.get_window_size() / Vector2(1920.0,1080.0))

func draw_systems():
	var map = $ParallaxBackground/ParallaxLayer0/Map
	var limits_systems = [ -1920, -1920, 1920, 1920 ]
	for i in Store._state.game.systems.keys():
		var system = system_scene.instance()
		system.set_name(Store._state.game.systems[i].id)
		system.system = Store._state.game.systems[i]
		map.add_child(system)
		limits_systems[0] = min(Utils.SCALE_SYSTEMS_COORDS * Store._state.game.systems[i].coordinates.x, limits_systems[0])
		limits_systems[1] = min(Utils.SCALE_SYSTEMS_COORDS * Store._state.game.systems[i].coordinates.y, limits_systems[1])
		limits_systems[2] = max(Utils.SCALE_SYSTEMS_COORDS * Store._state.game.systems[i].coordinates.x, limits_systems[2])
		limits_systems[3] = max(Utils.SCALE_SYSTEMS_COORDS * Store._state.game.systems[i].coordinates.y, limits_systems[3])
	return limits_systems
	
func update_fleet_system(fleet):
	Store.update_fleet_system(fleet)
	get_node("ParallaxBackground/ParallaxLayer0/Map/" + fleet.system).refresh_fleet_pins()
	if has_node("ParallaxBackground/ParallaxLayer0/Map/FleetContainer/" + fleet.id):
		get_node("ParallaxBackground/ParallaxLayer0/Map/FleetContainer/" + fleet.id).queue_free()
	
func _on_combat_ended(data):
	for fleet in data.fleets.values():
		if fleet.destination_system != null:
			get_node("ParallaxBackground/ParallaxLayer0/Map/FleetContainer/" + fleet.id).queue_free()
		if fleet.nb_ships == 0:
			Store.erase_fleet(fleet)
		else:
			Store.update_fleet_nb_ships(fleet,fleet.nb_ships)
	get_node("ParallaxBackground/ParallaxLayer0/Map/" + data.system.id).refresh_fleet_pins()
	
func _on_system_selected(system, old_system):
	if old_system != null:
		get_node("ParallaxBackground/ParallaxLayer0/Map/" + old_system.id).unselect()

func _on_player_income(data):
	Store.update_wallet(data.income)

# This method is called when the websocket notifies an another player's fleet creation
# It calls the same store method when the current player creates a new fleet
func _on_remote_fleet_created(fleet):
	Store.add_fleet(fleet)

# This method is called in both cases, to update the map's view
func _on_fleet_created(fleet):
	get_node("ParallaxBackground/ParallaxLayer0/Map/" + fleet.system).refresh_fleet_pins()

func _on_fleet_arrival(fleet):
	update_fleet_system(fleet)

func _on_fleet_sailed(fleet):
	Store._state.game.systems[fleet.system].fleets.erase(fleet.id)
	var sailing_fleet = moving_fleet_scene.instance()
	sailing_fleet.set_name(fleet.id)
	var origin_system = get_node("ParallaxBackground/ParallaxLayer0/Map/" + fleet.system)
	origin_system.refresh()
	sailing_fleet.fleet = fleet
	sailing_fleet.color = Store.get_player_color(Store.get_game_player(fleet.player))
	sailing_fleet.origin_position = origin_system.get_position()
	sailing_fleet.destination_position = get_node("ParallaxBackground/ParallaxLayer0/Map/" + fleet.destination_system).get_position()
	get_node("ParallaxBackground/ParallaxLayer0/Map/FleetContainer").add_child(sailing_fleet)

# This method is called when the websocket notifies an another player's fleet sailing
# It notifies the store which call _on_fleet_sailed back
func _on_remote_fleet_sailed(fleet):
	Store.fleet_sail(fleet)

func _on_system_conquerred(data):
	update_fleet_system(data.fleet)
	Store.update_system(data.system)
	get_node("ParallaxBackground/ParallaxLayer0/Map/" + data.system.id).refresh()
	
func _on_victory(data):
	Store._state.victorious_faction = data.victorious_faction
	Store._state.scores = data.scores
	emit_signal("scene_requested", "scores")

func _input(event):
	if event is InputEventKey || event is InputEventMouseButton:
		if event.is_action_pressed("ui_zoom_in_map"):
			$Camera2D.zoom.x = max($Camera2D.zoom.x / _ZOOM_FACTOR, pow(_ZOOM_FACTOR, _MIN_ZOOM_FACTOR))
			$Camera2D.zoom.y = max($Camera2D.zoom.y / _ZOOM_FACTOR, pow(_ZOOM_FACTOR, _MIN_ZOOM_FACTOR))
		if event.is_action_pressed("ui_zoom_out_map"):
			$Camera2D.zoom.x = min($Camera2D.zoom.x *_ZOOM_FACTOR,pow(_ZOOM_FACTOR, _MAX_ZOOM_FACTOR))
			$Camera2D.zoom.y = min($Camera2D.zoom.y *_ZOOM_FACTOR,pow(_ZOOM_FACTOR, _MAX_ZOOM_FACTOR))
		if event.is_action_pressed("ui_drag_map"):
			_is_map_being_dragged = true
		if event.is_action_released("ui_drag_map"):
			_is_map_being_dragged = false
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
	elif event is InputEventMouseMotion:
		if _is_map_being_dragged:
			_move_camera(-event.get_relative() * $Camera2D.zoom)
			_camera_speed = event.speed

func _move_camera(vector):
	var new_position = $Camera2D.position + vector
	new_position.x = max(min(new_position.x,$Camera2D.limit_right - OS.get_window_size().x/2 * $Camera2D.zoom.x ),$Camera2D.limit_left + OS.get_window_size().x/2 * $Camera2D.zoom.x)
	new_position.y = max(min(new_position.y,$Camera2D.limit_bottom - OS.get_window_size().y/2 * $Camera2D.zoom.y),$Camera2D.limit_top + OS.get_window_size().y/2 * $Camera2D.zoom.y)
	$Camera2D.position = new_position

func _process(delta):
	if ! _is_map_being_dragged:
		var key_motion_camera_speed = Vector2.ZERO
		for directions in _motion_camera.keys():
			if  _motion_camera[directions]:
				key_motion_camera_speed -= directions * CAMERA_MOVE_KEY_AMOUNT
		if key_motion_camera_speed != Vector2.ZERO:
			_camera_speed = key_motion_camera_speed /  $Camera2D.zoom
		if ! _camera_speed.is_equal_approx(Vector2.ZERO):
			_move_camera(- _camera_speed * delta  *  $Camera2D.zoom)
	# the vector is reduces even when dragging such that if we stop moving the mouse
	# but the button is held down. When it is release the camara does not move arround
	if ! _camera_speed.is_equal_approx(Vector2.ZERO):
		var sign_vector = _camera_speed.sign()
		var abs_vector = _camera_speed.abs()
		var coeff = CAMERA_DRAG_COEFF_WHEN_DRAGGING if _is_map_being_dragged else CAMERA_DRAG_COEFF
		abs_vector.x = max(abs_vector.x - coeff * delta * abs(_camera_speed.x) / _camera_speed.length(), 0.0)
		abs_vector.y = max(abs_vector.y - coeff * delta * abs(_camera_speed.y) / _camera_speed.length(), 0.0)
		_camera_speed = abs_vector * sign_vector
