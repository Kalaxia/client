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
const ASSETS = preload("res://resources/assets.tres")

export(float) var scale_ratio = 1.0 setget set_scale_ratio

var _game_data : GameData = Store.game_data
var system : System = null setget set_system
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


func _ready():
	_connect_system() # todo is this necessary
	range_draw_node.visible = false
	set_position(Vector2(system.coordinates.x , system.coordinates.y) * Utils.SCALE_SYSTEMS_COORDS)
	star.connect("mouse_input", self, "_on_mouse_input")
	star.connect("mouse_entered", self, "_on_mouse_entered")
	star.connect("mouse_exited", self, "_on_mouse_exited")
	_game_data.selected_state.connect("fleet_selected", self, "_on_fleet_selected")
	_game_data.selected_state.connect("fleet_unselected", self, "_on_fleet_unselected")
	var scale_factor = (1.0 / scale.x) if scale.x != 0 else 0.0
	var scale_range = ASSETS.constants.fleet_range * Utils.SCALE_SYSTEMS_COORDS * scale_factor
	range_draw_node.scale = Vector2(scale_range,scale_range)
	_set_crown_state()
	_set_system_texture()
	_set_glow_effet()
	_modulate_color(1.0)
	if _game_data.does_belong_to_current_player(system):
		_game_data.selected_state.select_system(system)
		refresh_scale()
	else :
		_set_target_scale(1.0)
	refresh_building_pins()


func _process(delta):
	_time += delta
	_process_modulate_alpha(delta)
	_process_modulate_scale(delta)


func set_system(new_system):
	_disconnect_system()
	system = new_system
	_connect_system()


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
		var p = _game_data.get_player(fleet.player)
		if not is_current_player_included and _game_data.is_current_player(p):
			is_current_player_included = true
			add_fleet_pin(p)
		elif not is_another_player_included and not _game_data.is_current_player(p):
			is_another_player_included = true
			add_fleet_pin(p)


func update_ship_pin():
	if system == null:
		return
	elif system.hangar == null:
		_update_ship_pin_number(0)
		return
	var total_number_of_ships_in_hangar = 0
	for i in system.hangar:
		total_number_of_ships_in_hangar += i.quantity
	_update_ship_pin_number(total_number_of_ships_in_hangar) 


func _update_ship_pin_number(number):
	for node in building_pins.get_children():
		if node.building.kind.kind == "shipyard":
			node.blinking = not number == 0


func add_fleet_pin(player):
	var fleet_pin = SYSTEM_FLEET_PIN_SCENE.instance()
	fleet_pin.faction = player.faction
	fleet_pin.is_current_player = _game_data.is_current_player(player)
	fleet_pin.color = _game_data.get_player_color(player)
	fleet_pins.add_child(fleet_pin)


func refresh():
	_set_system_texture()
	_set_glow_effet()
	# we need to refresh the color even if the alpha does not change 
	# as in _process we refresh only if alpha has to be modified
	_modulate_color(1.0) 
	refresh_fleet_pins()
	refresh_building_pins()
	crown.visible = _game_data.does_belong_to_current_player(system)
	refresh_scale()


func refresh_building_pins():
	for node in building_pins.get_children():
		node.queue_free()
	if system.buildings == null:
		return
	for building in system.buildings:
		var node = SYSTEM_BUILDING_PIN_SCENE.instance()
		node.building = building
		node.faction_color = _game_data.get_player(system.player).faction.get_color()
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
	var is_current_player = _game_data.does_belong_to_current_player(system)
	crown.visible = is_current_player
	if is_current_player:
		crown.texture = _game_data.get_player(system.player).faction.picto.crown_top


func _set_glow_effet():
	var is_victory_system = system.kind == "VictorySystem"
	light_glow_bg.visible = is_victory_system
	if is_victory_system:
		var color = get_color_of_system()
		light_glow_bg.color = color


func _set_system_texture():
	var faction = ASSETS.factions[0.0]
	if system.player:
		faction = _game_data.get_player(system.player).faction
	spot.texture = faction.picto.system_by_kind(system.kind)


func _scale_star_system(factor):
	star.set_scale(Vector2(scale_ratio * factor, scale_ratio * factor))
	fleet_pins.rect_position = _BASE_POSITION_PIN_FLEET * factor * scale_ratio
	building_pins.rect_position = _BASE_POSITION_PIN_BUILDING * factor * scale_ratio


func _set_target_scale(factor):
	_target_scale = factor


func _on_fleet_selected(_old_fleet):
	range_draw_node.visible = _game_data.selected_state.is_selected_system(system)


func _on_fleet_unselected(_old_fleet):
	range_draw_node.visible = false


func _modulate_color(alpha):
	var color = get_color_of_system()
	color.a = alpha
	star.set_modulate(color)


func _on_mouse_input(event):
	if event is InputEventMouseButton and event.is_pressed():
		if event.get_button_index() == BUTTON_LEFT:
			_game_data.selected_state.select_system(system)
			# no need to add sound because it is alreay played in the element
			_game_data.selected_state.select_system(system)
		elif event.get_button_index() == BUTTON_RIGHT \
				and _game_data.selected_state.selected_fleet != null \
				and _game_data.is_in_range(_game_data.selected_state.selected_fleet, system):
			# you can't set the same destination as the origin
			Network.req(self, "_on_fleet_send",
				"/api/games/" + _game_data.id 
						+ "/systems/" + _game_data.selected_state.selected_fleet.system 
						+ "/fleets/" + _game_data.selected_state.selected_fleet.id 
						+ "/travel/",
				HTTPClient.METHOD_POST,
				[ "Content-Type: application/json" ],
				JSON.print({ "destination_system_id" : system.id }),
				[_game_data.selected_state.selected_fleet, system]
			)


func _on_fleet_send(err, response_code, _headers, body, fleet : Fleet, _system_p : System):
	if err:
		ErrorHandler.network_response_error(err)
		return
	if response_code == HTTPClient.RESPONSE_OK:
		var data = JSON.parse(body.get_string_from_utf8()).result
		fleet.update_fleet(data)
		_game_data.fleet_sail(fleet)
		_game_data.selected_state.unselect_fleet()


func _on_mouse_entered():
	is_hover = true
	refresh_scale()
	is_in_range_sailing_fleet = _game_data.is_in_range(_game_data.selected_state.selected_fleet, system)


func _on_mouse_exited():
	is_hover = false
	is_in_range_sailing_fleet = false
	refresh_scale()


func refresh_scale():
	var scale_refreshed = _SCALE_FACTOR_ON_HIGHLIGHT if _game_data.does_belong_to_current_player(system) else 1.0
	if  _game_data.selected_state.is_selected_system(system) or is_hover:
		scale_refreshed *= _SCALE_FACTOR_ON_HIGHLIGHT
	_set_target_scale(scale_refreshed)


func set_scale_ratio(new_factor : float):
	scale_ratio = new_factor
	refresh_scale()


func get_color_of_system():
	var is_victory_system = system.kind == "VictorySystem"
	return _game_data.get_player_color(null, is_victory_system) \
			if system.player == null \
			else _game_data.get_player_color(_game_data.get_player(system.player), is_victory_system)


func _connect_system(system_p = system):
	if system_p  == null:
		return
	if not system_p.is_connected("fleet_added", self, "_on_fleet_created"):
		system_p.connect("fleet_added", self, "_on_fleet_created")
	if not system_p.is_connected("hangar_updated", self, "_on_hangar_updated"):
		system_p.connect("hangar_updated", self, "_on_hangar_updated")
	if not system_p.is_connected("building_updated", self, "_on_building_updated"):
		system_p.connect("building_updated", self, "_on_building_updated")
	if not system_p.is_connected("building_contructed", self, "_on_building_contructed"):
		system_p.connect("building_contructed", self, "_on_building_contructed")
	if not system_p.is_connected("fleet_owner_updated", self, "_on_fleet_owner_updated"):
		system_p.connect("fleet_owner_updated", self, "_on_fleet_owner_updated")
	


func _disconnect_system(system_p = system):
	if system_p  == null:
		return
	if system_p.is_connected("fleet_added", self, "_on_fleet_created"):
		system_p.disconnect("fleet_added", self, "_on_fleet_created")
	if system_p.is_connected("hangar_updated", self, "_on_hangar_updated"):
		system_p.disconnect("hangar_updated", self, "_on_hangar_updated")
	if system_p.is_connected("building_updated", self, "_on_building_updated"):
		system_p.disconnect("building_updated", self, "_on_building_updated")
	if system_p.is_connected("building_contructed", self, "_on_building_contructed"):
		system_p.disconnect("building_contructed", self, "_on_building_contructed")
	if system_p.is_connected("fleet_owner_updated", self, "_on_fleet_owner_updated"):
		system_p.disconnect("fleet_owner_updated", self, "_on_fleet_owner_updated")


func _on_building_contructed(building):
	Audio.building_constructed_audio(building)


func _on_fleet_owner_updated():
	refresh_fleet_pins()


func _on_fleet_created(_fleet : Fleet):
	refresh_fleet_pins()


func _on_hangar_updated(_ship_group_hangar):
	update_ship_pin()


func _on_building_updated():
	refresh_building_pins()
