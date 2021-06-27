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
const SYSTEM_COMBAT_PIN_SCENE = preload("res://game/map/combat_pin.tscn")
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
var _lock_fleet_pin_refresh = Utils.Lock.new()
var _has_combat = false
var _is_being_conquerred = false

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
	if _is_being_conquerred && !_has_combat:
		progress_conquest(delta)


func set_system(new_system):
	_disconnect_system()
	system = new_system
	_connect_system()


func unselect():
	refresh_scale()


func select():
	refresh_scale()


func refresh_fleet_pins():
	if not _lock_fleet_pin_refresh.try_lock():
		return
	for pin in fleet_pins.get_children():
		pin.queue_free()
	while fleet_pins.get_child_count() > 0:
		var node = fleet_pins.get_child(0)
		if node.is_inside_tree():
			yield(node, "tree_exited")
		else:
			yield(Engine.get_main_loop(), "idle_frame")
	var player_dict = {}
	var is_current_player_included = {}
	var is_another_player_included = {}
	for fleet in system.fleets.values():
		var p = _game_data.get_player(fleet.player)
		var faction_id = p.faction.id
		if player_dict.has(faction_id):
			if _game_data.is_current_player(p) and not is_current_player_included[faction_id]:
				is_current_player_included[faction_id] = true
				player_dict[faction_id].push_front(p)
			elif not _game_data.is_current_player(p) and not is_another_player_included[faction_id]:
				is_another_player_included[faction_id] = true
				player_dict[faction_id].push_back(p)
		else:
			player_dict[faction_id] = [p]
			is_current_player_included[faction_id] = _game_data.is_current_player(p)
			is_another_player_included[faction_id] = not _game_data.is_current_player(p)
	var keys_sorted = player_dict.keys()
	keys_sorted.sort()
	_has_combat = keys_sorted.size() > 1
	for index in range(keys_sorted.size()):
		for player in player_dict[keys_sorted[index]]:
			add_fleet_pin(player)
		if index != keys_sorted.size() - 1:
			add_combat_pin()
	_lock_fleet_pin_refresh.unlock()


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


func add_fleet_pin(player, raise = false):
	var fleet_pin = SYSTEM_FLEET_PIN_SCENE.instance()
	fleet_pin.faction = player.faction
	fleet_pin.is_current_player = _game_data.is_current_player(player)
	fleet_pin.color = _game_data.get_player_color(player)
	fleet_pins.add_child(fleet_pin)
	if raise:
		fleet_pin.raise()


func add_combat_pin():
	var combat_pin = SYSTEM_COMBAT_PIN_SCENE.instance()
	fleet_pins.add_child(combat_pin)

func refresh():
	_set_system_texture()
	_set_glow_effet()
	# we need to refresh the color even if the alpha does not change 
	# as in _process we refresh only if alpha has to be modified
	_modulate_color(1.0) 
	refresh_fleet_pins()
	refresh_building_pins()
	if not _game_data.does_belong_to_current_player(system):
		range_draw_node.visible = false
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
	light_glow_bg.visible = _is_victory_system()
	if light_glow_bg.visible:
		var color = get_color_of_system()
		light_glow_bg.color = color


func _get_system_texture() -> Texture:
	var faction = ASSETS.factions[0.0]
	if system.player:
		faction = _game_data.get_player(system.player).faction
	return faction.picto.system_by_kind(system.kind)


func _set_system_texture():
	spot.texture = _get_system_texture()


func _scale_star_system(factor):
	star.set_scale(Vector2(scale_ratio * factor, scale_ratio * factor))
	_set_pins_positions(factor)


func _set_pins_positions(factor):
	fleet_pins.rect_position = _BASE_POSITION_PIN_FLEET * factor * scale_ratio - Vector2(fleet_pins.rect_size.x, 0.0)
	# we need set the position taking into account the size
	building_pins.rect_position = _BASE_POSITION_PIN_BUILDING * factor * scale_ratio


func _is_victory_system():
	return system.kind == "VictorySystem"

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
	var is_victory_system = _is_victory_system()
	return _game_data.get_player_color(null, is_victory_system) \
			if system.player == null \
			else _game_data.get_player_color(_game_data.get_player(system.player), is_victory_system)


func _connect_system(system_p = system):
	if system_p  == null:
		return
	if not system_p.is_connected("battle_started", self, "_on_battle_started"):
		system_p.connect("battle_started", self, "_on_battle_started")
	if not system_p.is_connected("battle_ended", self, "_on_battle_ended"):
		system_p.connect("battle_ended", self, "_on_battle_ended")
	if not system_p.is_connected("fleet_added", self, "_on_fleet_created"):
		system_p.connect("fleet_added", self, "_on_fleet_created")
	if not system_p.is_connected("hangar_updated", self, "_on_hangar_updated"):
		system_p.connect("hangar_updated", self, "_on_hangar_updated")
	if not system_p.is_connected("building_updated", self, "_on_building_updated"):
		system_p.connect("building_updated", self, "_on_building_updated")
	if not system_p.is_connected("building_constructed", self, "_on_building_constructed"):
		system_p.connect("building_constructed", self, "_on_building_constructed")
	if not system_p.is_connected("fleet_owner_updated", self, "_on_fleet_owner_updated"):
		system_p.connect("fleet_owner_updated", self, "_on_fleet_owner_updated")
	if not system_p.is_connected("conquest_started", self, "_on_conquest_started"):
		system_p.connect("conquest_started", self, "_on_conquest_started")
	if not system_p.is_connected("conquest_updated", self, "_on_conquest_updated"):
		system_p.connect("conquest_updated", self, "_on_conquest_updated")
	if not system_p.is_connected("conquest_success", self, "_on_conquest_success"):
		system_p.connect("conquest_success", self, "_on_conquest_success")
	if not system_p.is_connected("conquest_cancelled", self, "_on_conquest_cancelled"):
		system_p.connect("conquest_cancelled", self, "_on_conquest_cancelled")
	


func _disconnect_system(system_p = system):
	if system_p  == null:
		return
	if system_p.is_connected("battle_started", self, "_on_battle_started"):
		system_p.disconnect("battle_started", self, "_on_battle_started")
	if system_p.is_connected("battle_ended", self, "_on_battle_ended"):
		system_p.disconnect("battle_ended", self, "_on_battle_ended")
	if system_p.is_connected("fleet_added", self, "_on_fleet_created"):
		system_p.disconnect("fleet_added", self, "_on_fleet_created")
	if system_p.is_connected("hangar_updated", self, "_on_hangar_updated"):
		system_p.disconnect("hangar_updated", self, "_on_hangar_updated")
	if system_p.is_connected("building_updated", self, "_on_building_updated"):
		system_p.disconnect("building_updated", self, "_on_building_updated")
	if system_p.is_connected("building_constructed", self, "_on_building_constructed"):
		system_p.disconnect("building_constructed", self, "_on_building_constructed")
	if system_p.is_connected("fleet_owner_updated", self, "_on_fleet_owner_updated"):
		system_p.disconnect("fleet_owner_updated", self, "_on_fleet_owner_updated")
	if system_p.is_connected("conquest_started", self, "_on_conquest_started"):
		system_p.disconnect("conquest_started", self, "_on_conquest_started")
	if system_p.is_connected("conquest_updated", self, "_on_conquest_updated"):
		system_p.disconnect("conquest_updated", self, "_on_conquest_updated")
	if system_p.is_connected("conquest_success", self, "_on_conquest_success"):
		system_p.disconnect("conquest_success", self, "_on_conquest_success")
	if system_p.is_connected("conquest_cancelled", self, "_on_conquest_cancelled"):
		system_p.disconnect("conquest_cancelled", self, "_on_conquest_cancelled")


func _on_building_constructed(building):
	Audio.building_constructed_audio(building)


func _on_fleet_owner_updated(_fleet):
	refresh_fleet_pins()


func _on_fleet_created(_fleet : Fleet):
	refresh_fleet_pins()


func _on_hangar_updated(_ship_group_hangar):
	update_ship_pin()


func _on_building_updated():
	refresh_building_pins()


func _on_battle_started(battle):
	_has_combat = true
	var factions = []
	
	for faction in battle.fleets:
		if !factions.has(faction):
			add_battle_party(battle.fleets[faction].values()[0].player)
			factions.push_back(faction)
	
	refresh_fleet_pins()


# @TODO : use faction_id instead
func add_battle_party(player_id):
	var animation = CPUParticles2D.new()
	animation.set_name("BattleAnimation" + player_id)
	animation.amount = 8
	animation.spread = 180
	animation.gravity = Vector2(0,0)
	animation.emission_shape = animation.EMISSION_SHAPE_SPHERE
	animation.emission_sphere_radius = 21
	animation.initial_velocity = 10
	
	animation.color = _game_data.get_player_color(_game_data.get_player(player_id))
	
	add_child(animation)
	animation.add_to_group("battle_animations")


func _on_battle_ended(battle):
	_has_combat = false
	
	for animation in get_tree().get_nodes_in_group("battle_animations"):
		animation.queue_free()
	
	refresh_fleet_pins()


func _on_conquest_started(conquest):
	var is_victory_system = _is_victory_system()
	
	var progress = TextureProgress.new()
	progress.set_name("ConquestProgress")
	progress.set_scale(Vector2(0.15, 0.15))
	progress.max_value = get_conquest_duration(conquest)
	progress.fill_mode = TextureProgress.FILL_CLOCKWISE
	progress.texture_under = _get_system_texture()
	progress.texture_progress = _get_system_texture()
	progress.tint_under = get_color_of_system()
	progress.tint_progress = _game_data.get_player_color(_game_data.get_player(conquest.player), is_victory_system)
	
	$Star.add_child(progress)
	$Star/Spot.visible = false
	
	_is_being_conquerred = true


func _on_conquest_updated(conquest):
	var progress = $Star.get_node("ConquestProgress")
	var conquest_duration = get_conquest_duration(conquest)
	progress.max_value = conquest_duration
	progress.value = 0


func _on_conquest_success():
	_is_being_conquerred = false
	
	var progress = $Star/ConquestProgress
	progress.set_name("OverConquestProgress")
	progress.queue_free()
	$Star/Spot.visible = true


func _on_conquest_cancelled():
	_is_being_conquerred = false
	
	var progress = $Star/ConquestProgress
	progress.set_name("OverConquestProgress")
	progress.queue_free()
	$Star/Spot.visible = true


func get_conquest_duration(conquest):
	return conquest.ended_at - conquest.started_at


func progress_conquest(delta):
	var progress = $Star/ConquestProgress
	if progress != null:
		progress.value += delta * 1000
