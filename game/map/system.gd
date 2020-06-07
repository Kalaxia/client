extends Node2D

var system = null
var is_hover = false
var scale_ratio = 1.0
var system_fleet_pin_scene = preload("res://game/map/system_fleet_pin.tscn")
var is_in_range_sailing_fleet = false
var _time = 0.0
var _previous_alpha = 1.0
var _previous_alpha_deriv = 0.0 # in alpha per second

const ALPHA_SPEED_GAIN = 2 #in alpha per second^2
const SNAP_ALPHA_DISTANCE = 0.05

func _ready():
	set_position(Vector2(system.coordinates.x * 50, system.coordinates.y * 50))
	_modulate_color(1.0)
	$Star.connect("input_event", self, "_on_input_event")
	$Star.connect("mouse_entered", self, "_on_mouse_entered")
	$Star.connect("mouse_exited", self, "_on_mouse_exited")
	Store.connect("fleet_selected",self,"_on_fleet_selected")
	Store.connect("fleet_unselected",self,"_on_fleet_unselected")
	
	if system.player == Store._state.player.id:
		Store.select_system(system)
		$Star.set_scale(Vector2(scale_ratio * 2, scale_ratio * 2))
		
func _process(delta):
	_time += delta
	var target_alpha = 1.0
	if is_in_range_sailing_fleet:
		target_alpha = cos (_time * PI ) * 0.4 +0.6
	if _previous_alpha != target_alpha:
		_previous_alpha = max(min( (target_alpha-_previous_alpha)*ALPHA_SPEED_GAIN * delta + _previous_alpha,1.0),0.0)
		if abs(target_alpha-_previous_alpha)<SNAP_ALPHA_DISTANCE:
			_previous_alpha=target_alpha
		_modulate_color(_previous_alpha)

func _on_fleet_selected(fleet):
	is_in_range_sailing_fleet = Store.is_in_range(fleet,system)

func _on_fleet_unselected():
	is_in_range_sailing_fleet = false

func _modulate_color(alpha):
	var star_sprite = get_node("Star/Sprite")
	if system.player != null:
		var player = Store.get_game_player(system.player)
		var faction = Store.get_faction(player.faction)
		star_sprite.set_modulate(Color(faction.color[0]/255.0, faction.color[1]/255.0, faction.color[2]/255.0,alpha))
	else:
		star_sprite.set_modulate(Color(1.0,1.0,1.0,alpha))
	
func unselect():
	if system.player == null || system.player != Store._state.player.id:
		$Star.set_scale(Vector2(scale_ratio, scale_ratio))
		
func refresh_fleet_pins():
	var factions = []
	for pin in $FleetPins.get_children(): pin.queue_free()
	for fleet in system.fleets.values():
		var p = Store.get_game_player(fleet.player)
		if !factions.has(p.faction):
			factions.push_back(p.faction)
			add_fleet_pin(p.faction, Store.get_faction(p.faction).color)
		
func add_fleet_pin(faction, color):
	var fleet_pin = system_fleet_pin_scene.instance()
	fleet_pin.faction = faction
	fleet_pin.color = color
	$FleetPins.add_child(fleet_pin)

func refresh():
	system = Store._state.game.systems[system.id]
	_modulate_color(1.0)
	refresh_fleet_pins()
	if system.player == Store._state.player.id:
		$Star.set_scale(Vector2(scale_ratio * 2, scale_ratio * 2))

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.is_pressed():
		if event.get_button_index() == BUTTON_LEFT:
			Store.select_system(system)
		elif event.get_button_index() == BUTTON_RIGHT && Store._state.selected_fleet != null && Store._state.selected_fleet.system != system.id:
			# you can't set the same destination as the origin
			Network.req(self, "_on_fleet_send"
				, "/api/games/" + Store._state.game.id + "/systems/" + Store._state.selected_fleet.system + "/fleets/" + Store._state.selected_fleet.id + "/travel/"
				, [ "Content-Type: application/json" ]
				, HTTPClient.METHOD_POST
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
	$Star.set_scale(Vector2(scale_ratio * 2, scale_ratio * 2))
	
func _on_mouse_exited():
	is_hover = false
	if system.player != Store._state.player.id && system != Store._state.selected_system:
		$Star.set_scale(Vector2(scale_ratio, scale_ratio))
