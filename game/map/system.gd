extends Node2D

var system = null
var is_hover = false
export(float) var scale_ratio = 1.0 setget set_scale_ratio
var system_fleet_pin_scene = preload("res://game/map/system_fleet_pin.tscn")
var is_in_range_sailing_fleet = false
var _time = 0.0
var _alpha = 1.0
var _target_scale = scale_ratio
var _current_scale = scale_ratio


const ALPHA_SPEED_GAIN = 2.0
const SNAP_ALPHA_DISTANCE = 0.05
const ALPHA_APLITUDE = 0.4
const BASE_POSITION_PIN = Vector2(-30.0,-30.0)
const SCALE_FACTOR_ON_HIGHLIGHT = 1.5
const _SCALE_CHANGE_FACTOR = 5.0

const _TEXTURE_SYSTEM = {
	0 : preload("res://resources/assets/2d/map/Picto_syteme.png"),
	1 : preload("res://resources/assets/2d/map/kalankar/Picto_syteme_masqueV2-01.png"),
	2 : preload("res://resources/assets/2d/map/valkar/Picto_syteme_serpentV2-01.png"),
	3 : preload("res://resources/assets/2d/map/adranite/Picto_syteme_epeeV2-01.png"),
}


const _TEXTURE_CROWN = {
	1 : preload("res://resources/assets/2d/map/kalankar/couronne.png"),
	2 : preload("res://resources/assets/2d/map/valkar/couronne.png"),
	3 : preload("res://resources/assets/2d/map/adranite/couronne.png"),
}

func _ready():
	set_position(Vector2(system.coordinates.x * 50, system.coordinates.y * 50))
	_set_system_texture()
	_modulate_color(1.0)
	$Star.connect("input_event", self, "_on_input_event")
	$Star.connect("mouse_entered", self, "_on_mouse_entered")
	$Star.connect("mouse_exited", self, "_on_mouse_exited")
	Store.connect("fleet_selected",self,"_on_fleet_selected")
	Store.connect("fleet_unselected",self,"_on_fleet_unselected")
	_set_crown_state()
	if system.player == Store._state.player.id:
		Store.select_system(system)
		_set_target_scale(SCALE_FACTOR_ON_HIGHLIGHT)
	else :
		_set_target_scale(1.0)
		
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
	if ! is_equal_approx(_target_scale,_current_scale):
		if _target_scale > _current_scale:
			_current_scale = min(_current_scale + _SCALE_CHANGE_FACTOR * delta, _target_scale)
		else:
			_current_scale = max(_current_scale - _SCALE_CHANGE_FACTOR * delta, _target_scale)
		_scale_star_system(_current_scale)

func _set_crown_state():
	var is_current_player = (system.player == Store._state.player.id)
	$Star/Crown.visible = is_current_player
	if is_current_player:
		$Star/Crown.texture = _TEXTURE_CROWN[Store.get_game_player(system.player).faction as int]

func _set_system_texture():
	if system.player == null:
		$Star/Spot.texture = _TEXTURE_SYSTEM[0]
	else:
		$Star/Spot.texture = _TEXTURE_SYSTEM[Store.get_game_player(system.player).faction as int]

func _scale_star_system(factor):
	$Star.set_scale(Vector2(scale_ratio * factor, scale_ratio * factor))
	$FleetPins.rect_position = BASE_POSITION_PIN * factor * scale_ratio

func _set_target_scale(factor):
	_target_scale = factor

func _on_fleet_selected(fleet):
	is_in_range_sailing_fleet = Store.is_in_range(fleet,system)

func _on_fleet_unselected():
	is_in_range_sailing_fleet = false

func _modulate_color(alpha):
	var star_sprite = get_node("Star")
	var color = Store.get_player_color(null) if system.player == null else Store.get_player_color(Store.get_game_player(system.player))
	color.a = alpha
	star_sprite.set_modulate(color)
	
func unselect():
	if system.player == null || system.player != Store._state.player.id:
		_set_target_scale(1.0)
		
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
	fleet_pin.color = Store.get_player_color(player)
	$FleetPins.add_child(fleet_pin)

func refresh():
	system = Store._state.game.systems[system.id]
	_set_system_texture()
	_modulate_color(1.0)
	refresh_fleet_pins()
	get_node("Star/Crown").visible = (system.player == Store._state.player.id)
	if system.player == Store._state.player.id:
		_set_target_scale(SCALE_FACTOR_ON_HIGHLIGHT)
	else:
		_set_target_scale(1.0)

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
	_set_target_scale(SCALE_FACTOR_ON_HIGHLIGHT)
	
func _on_mouse_exited():
	is_hover = false
	if system.player != Store._state.player.id && system != Store._state.selected_system:
		_set_target_scale(1.0)

func refresh_scale():
	if is_hover || system.player == Store._state.player.id:
		_set_target_scale(SCALE_FACTOR_ON_HIGHLIGHT)
	else:
		_set_target_scale(1.0)

func set_scale_ratio(new_factor : float):
	scale_ratio = new_factor
	refresh_scale()
