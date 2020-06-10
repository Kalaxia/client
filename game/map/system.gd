extends Node2D

var system = null
var is_hover = false
var scale_ratio = 1.0
var system_fleet_pin_scene = preload("res://game/map/system_fleet_pin.tscn")
var is_in_range_sailing_fleet = false
var _time = 0.0
var _alpha = 1.0

const ALPHA_SPEED_GAIN = 2.0
const SNAP_ALPHA_DISTANCE = 0.05
const ALPHA_APLITUDE = 0.4
const _TEXTURE_FACTION_0 = preload("res://resources/assets/2d/map/spot.png")
const _TEXTURE_FACTION_1 = preload("res://resources/assets/2d/map/spot_faction_1.png")
const _TEXTURE_FACTION_2 = preload("res://resources/assets/2d/map/spot_faction_2.png")
const _TEXTURE_FACTION_3 = preload("res://resources/assets/2d/map/spot_faction_3.png")

func _ready():
	set_position(Vector2(system.coordinates.x * 50, system.coordinates.y * 50))
	_set_system_texture()
	_modulate_color(1.0)
	$Star.connect("input_event", self, "_on_input_event")
	$Star.connect("mouse_entered", self, "_on_mouse_entered")
	$Star.connect("mouse_exited", self, "_on_mouse_exited")
	Store.connect("fleet_selected",self,"_on_fleet_selected")
	Store.connect("fleet_unselected",self,"_on_fleet_unselected")
	get_node("Star/Crown").visible = (system.player == Store._state.player.id)
	if system.player == Store._state.player.id:
		Store.select_system(system)
		_scale_star_system_2()
		
func _process(delta):
	_time += delta
	var target_alpha = 1.0
	if is_in_range_sailing_fleet:
		target_alpha = cos (_time * PI ) * ALPHA_APLITUDE + (1.0-ALPHA_APLITUDE)
	if _alpha != target_alpha:
		_alpha = max(min( (target_alpha - _alpha) * ALPHA_SPEED_GAIN * delta + _alpha,1.0),0.0)
		if abs(target_alpha-_alpha)<SNAP_ALPHA_DISTANCE:
			_alpha=target_alpha
		_modulate_color(_alpha)

func _set_system_texture():
	if system.player == null:
		$Star/Spot.texture = _TEXTURE_FACTION_0
	else:
		match Store.get_game_player(system.player).faction as int:
			1:
				$Star/Spot.texture = _TEXTURE_FACTION_1
			2:
				$Star/Spot.texture = _TEXTURE_FACTION_2
			3:
				$Star/Spot.texture = _TEXTURE_FACTION_3
			_:
				$Star/Spot.texture = _TEXTURE_FACTION_0

func _scale_star_system_2():
	$Star.set_scale(Vector2(scale_ratio * 2, scale_ratio * 2))
	$FleetPins.set_position(Vector2(-36,-44))

func _scale_star_system_1():
	$Star.set_scale(Vector2(scale_ratio, scale_ratio))
	$FleetPins.set_position(Vector2(-26,-34))

func _on_fleet_selected(fleet):
	is_in_range_sailing_fleet = Store.is_in_range(fleet,system)

func _on_fleet_unselected():
	is_in_range_sailing_fleet = false

func _modulate_color(alpha):
	var star_sprite = get_node("Star/Spot")
	var color
	if system.player != null:
		 color = Store.get_color_player(Store.get_game_player(system.player))
	else:
		color =  Store.get_color_player(null)
	color.a = alpha
	star_sprite.set_modulate(color)
	
func unselect():
	if system.player == null || system.player != Store._state.player.id:
		_scale_star_system_1()
		
func refresh_fleet_pins():
	var is_current_player_included = false
	var is_another_player_included = false
	for pin in $FleetPins.get_children(): pin.queue_free()
	for fleet in system.fleets.values():
		var p = Store.get_game_player(fleet.player)
		if !is_current_player_included && p.id == Store._state.player.id:
			is_current_player_included = true
			add_fleet_pin(p)
		elif !is_another_player_included && p.id != Store._state.player.id:
			is_another_player_included = true
			add_fleet_pin(p)
		
func add_fleet_pin(player):
	var fleet_pin = system_fleet_pin_scene.instance()
	fleet_pin.faction = player.faction
	fleet_pin.is_current_player = (player.id == Store._state.player.id)
	fleet_pin.color = Store.get_color_player(player)
	$FleetPins.add_child(fleet_pin)

func refresh():
	system = Store._state.game.systems[system.id]
	_set_system_texture()
	_modulate_color(1.0)
	refresh_fleet_pins()
	get_node("Star/Crown").visible = (system.player == Store._state.player.id)
	if system.player == Store._state.player.id:
		_scale_star_system_2()
	else:
		_scale_star_system_1()

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.is_pressed():
		if event.get_button_index() == BUTTON_LEFT:
			Store.select_system(system)
		elif event.get_button_index() == BUTTON_RIGHT && Store._state.selected_fleet != null && Store.is_in_range(Store._state.selected_fleet,system) :
			# you can't set the same destination as the origin
			Network.req(self, "_on_fleet_send"
				, "/api/games/" + Store._state.game.id + "/systems/" + Store._state.selected_fleet.system + "/fleets/" + Store._state.selected_fleet.id + "/travel/"
				, HTTPClient.METHOD_POST
				, [ "Content-Type: application/json" ]
				, JSON.print({ "destination_system_id":system.id })
			)

func _on_fleet_send(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
		return
	if response_code == HTTPClient.RESPONSE_NO_CONTENT:
		Store._state.selected_fleet.destination_system = system.id
		Store.fleet_sail(Store._state.selected_fleet)
		Store.unselect_fleet()

func _on_mouse_entered():
	is_hover = true
	_scale_star_system_2()
	
func _on_mouse_exited():
	is_hover = false
	if system.player != Store._state.player.id && system != Store._state.selected_system:
		_scale_star_system_1()
