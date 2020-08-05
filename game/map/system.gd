extends Node2D

const _ALPHA_SPEED_GAIN = 2.0
const _SNAP_ALPHA_DISTANCE = 0.05
const _ALPHA_APLITUDE = 0.4
const _BASE_POSITION_PIN_FLEET = Vector2(-20.0, -30.0)
const _BASE_POSITION_PIN_BUILDING = Vector2(20.0, -30.0)
const _BASE_POSITION_PIN_SHIP = Vector2(-7.5, -50.0)
const _SCALE_FACTOR_ON_HIGHLIGHT = 1.5
const _SCALE_CHANGE_FACTOR = 5.0
const SYSTEM_FLEET_PIN_SCENE = preload("res://game/map/system_fleet_pin.tscn")
const SYSTEM_BUILDING_PIN_SCENE = preload("res://game/map/system_building_pin.tscn")

export(float) var scale_ratio = 1.0 setget set_scale_ratio

var system = null
var is_hover = false
var is_in_range_sailing_fleet = false
var _time = 0.0
var _alpha = 1.0
var _target_scale = scale_ratio
var _current_scale = scale_ratio

onready var light_glow_bg = $Star/Light2DGlowBG
onready var star = $Star
onready var crown = $Star/Crown
onready var spot = $Star/Spot
onready var fleet_pins = $FleetPins
onready var range_draw_node = $Range
onready var building_pins = $BuildingPins

const assets = preload("res://resources/assets.tres")


func _ready():
	range_draw_node.visible = false
	set_position(Vector2(system.coordinates.x , system.coordinates.y) * Utils.SCALE_SYSTEMS_COORDS)
	star.connect("mouse_input", self, "_on_mouse_input")
	star.connect("mouse_entered", self, "_on_mouse_entered")
	star.connect("mouse_exited", self, "_on_mouse_exited")
	Store.connect("fleet_selected", self, "_on_fleet_selected")
	Store.connect("fleet_unselected", self, "_on_fleet_unselected")
	var scale_factor = (1.0 / scale.x) if scale.x != 0 else 0.0
	var scale_range = Utils.fleet_range * Utils.SCALE_SYSTEMS_COORDS * scale_factor
	range_draw_node.scale = Vector2(scale_range,scale_range)
	_set_crown_state()
	_set_system_texture()
	_set_glow_effet()
	_modulate_color(1.0)
	if system.player == Store._state.player.id:
		Store.select_system(system)
		refresh_scale()
	else :
		_set_target_scale(1.0)
	refresh_building_pins()


func _process(delta):
	_time += delta
	_process_modulate_alpha(delta)
	_process_modulate_scale(delta)


func unselect():
	refresh_scale()


func select():
	refresh_scale()


func refresh_fleet_pins():
	var is_current_player_included = false
	var is_another_player_included = false
	for pin in fleet_pins.get_children():
		pin.queue_free()
	for fleet in system.fleets.values():
		var p = Store.get_game_player(fleet.player)
		if not is_current_player_included and p.id == Store._state.player.id:
			is_current_player_included = true
			add_fleet_pin(p)
		elif not is_another_player_included and p.id != Store._state.player.id:
			is_another_player_included = true
			add_fleet_pin(p)


func update_ship_pin():
	if system == null:
		return
	elif not system.has("hangar") or system.hangar == null:
		_update_ship_pin_number(0)
		return
	var total_number_of_ships_in_hangar = 0
	for i in system.hangar:
		total_number_of_ships_in_hangar += i.quantity
	_update_ship_pin_number(total_number_of_ships_in_hangar) 


func _update_ship_pin_number(number):
	for node in building_pins.get_children():
		if node.building.kind == "shipyard":
			node.blinking = not(number == 0)


func add_fleet_pin(player):
	var fleet_pin = SYSTEM_FLEET_PIN_SCENE.instance()
	fleet_pin.faction = player.faction
	fleet_pin.is_current_player = (player.id == Store._state.player.id)
	fleet_pin.color = Store.get_player_color(player)
	fleet_pins.add_child(fleet_pin)


func refresh():
	system = Store._state.game.systems[system.id]
	_set_system_texture()
	_set_glow_effet()
	_modulate_color(1.0) # we need to refresh the color even if the alpha does not change as in _process we refresh only if alpha has to be modified
	refresh_fleet_pins()
	refresh_building_pins()
	crown.visible = (system.player == Store._state.player.id)
	refresh_scale()


func refresh_building_pins():
	for node in building_pins.get_children():
		node.queue_free()
	if not system.has("buildings") or system.buildings == null:
		return
	for building in system.buildings:
		var node = SYSTEM_BUILDING_PIN_SCENE.instance()
		node.building = building
		node.faction_color = Store._get_faction_color(Store.get_faction(Store.get_game_player(system.player).faction))
		building_pins.add_child(node)
	update_ship_pin()


func _process_modulate_alpha(delta):
	var target_alpha = 1.0
	if is_in_range_sailing_fleet:
		target_alpha = cos(_time * PI ) * _ALPHA_APLITUDE + (1.0 - _ALPHA_APLITUDE)
	if  not is_equal_approx(_alpha, target_alpha):
		_alpha = clamp((target_alpha - _alpha) * _ALPHA_SPEED_GAIN * delta + _alpha, 0.0, 1.0)
		if abs(target_alpha - _alpha) < _SNAP_ALPHA_DISTANCE:
			_alpha = target_alpha
		_modulate_color(_alpha)


func _process_modulate_scale(delta):
	if not is_equal_approx(_target_scale, _current_scale):
		if _target_scale > _current_scale:
			_current_scale = min(_current_scale + _SCALE_CHANGE_FACTOR * delta, _target_scale)
		else:
			_current_scale = max(_current_scale - _SCALE_CHANGE_FACTOR * delta, _target_scale)
		_scale_star_system(_current_scale)


func _set_crown_state():
	var is_current_player = (system.player == Store._state.player.id)
	crown.visible = is_current_player
	if is_current_player:
		crown.texture = assets.factions[Store.get_game_player(system.player).faction].picto.crown_bottom


func _set_glow_effet():
	var is_victory_system = system.kind == "VictorySystem"
	light_glow_bg.visible = is_victory_system
	if is_victory_system:
		var color = get_color_of_system()
		light_glow_bg.color = color


func _set_system_texture():
	var faction = assets.factions.neutral
	if system.player:
		system = assets.factions[Store.get_game_player(system.player).faction]
	spot.texture = faction.system_by_kind(system.kind)


func _scale_star_system(factor):
	star.set_scale(Vector2(scale_ratio * factor, scale_ratio * factor))
	fleet_pins.rect_position = _BASE_POSITION_PIN_FLEET * factor * scale_ratio
	building_pins.rect_position = _BASE_POSITION_PIN_BUILDING * factor * scale_ratio


func _set_target_scale(factor):
	_target_scale = factor


func _on_fleet_selected(fleet):
	range_draw_node.visible = (fleet.system == system.id)


func _on_fleet_unselected():
	range_draw_node.visible = false


func _modulate_color(alpha):
	var color = get_color_of_system()
	color.a = alpha
	star.set_modulate(color)


func _on_mouse_input(event):
	if event is InputEventMouseButton and event.is_pressed():
		if event.get_button_index() == BUTTON_LEFT:
			Store.select_system(system)
		elif event.get_button_index() == BUTTON_RIGHT and Store._state.selected_fleet != null and Store.is_in_range(Store._state.selected_fleet,system):
			# you can't set the same destination as the origin
			Network.req(self, "_on_fleet_send"
				, "/api/games/" + Store._state.game.id + "/systems/" + Store._state.selected_fleet.system + "/fleets/" + Store._state.selected_fleet.id + "/travel/"
				, HTTPClient.METHOD_POST
				, [ "Content-Type: application/json" ]
				, JSON.print({ "destination_system_id" : system.id })
			)


func _on_fleet_send(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
		return
	if response_code == HTTPClient.RESPONSE_OK:
		var data = JSON.parse(body.get_string_from_utf8()).result
		Store._state.selected_fleet.destination_system = system.id
		Store.fleet_sail(Store._state.selected_fleet, data.destination_arrival_date)
		Store.unselect_fleet()


func _on_mouse_entered():
	is_hover = true
	refresh_scale()
	is_in_range_sailing_fleet = Store.is_in_range(Store._state.selected_fleet, system)


func _on_mouse_exited():
	is_hover = false
	is_in_range_sailing_fleet = false
	refresh_scale()


func refresh_scale():
	var scale_refreshed = _SCALE_FACTOR_ON_HIGHLIGHT if system.player == Store._state.player.id else 1.0
	if system == Store._state.selected_system or is_hover:
		scale_refreshed *= _SCALE_FACTOR_ON_HIGHLIGHT
	_set_target_scale(scale_refreshed)


func set_scale_ratio(new_factor : float):
	scale_ratio = new_factor
	refresh_scale()


func get_color_of_system():
	var is_victory_system = system.kind == "VictorySystem"
	return Store.get_player_color(null, is_victory_system) if system.player == null else Store.get_player_color(Store.get_game_player(system.player),is_victory_system)
