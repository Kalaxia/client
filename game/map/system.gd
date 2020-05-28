extends Node2D

var system = null
var is_hover = false
var scale_ratio = 1
var system_fleet_pin_scene = preload("res://game/map/system_fleet_pin.tscn")

func _ready():
	set_position(Vector2(system.coordinates.x * 50, system.coordinates.y * 50))
	init_color()
	$Star.connect("input_event", self, "_on_input_event")
	$Star.connect("mouse_entered", self, "_on_mouse_entered")
	$Star.connect("mouse_exited", self, "_on_mouse_exited")
	if system.player == Store._state.player.id:
		Store.select_system(system)
		$Star.set_scale(Vector2(scale_ratio * 2, scale_ratio * 2))
	
func init_color():
	var star_sprite = get_node("Star/Sprite")
	star_sprite.set_modulate(Color(1,1,1))
	if system.player != null:
		var player = Store.get_game_player(system.player)
		var faction = Store.get_faction(player.faction)
		star_sprite.set_modulate(Color(faction.color[0], faction.color[1], faction.color[2]))
		
func unselect():
	if system.player == null || system.player != Store._state.player.id:
		$Star.set_scale(Vector2(scale_ratio, scale_ratio))
		
func add_fleet(fleet):
	var color = Store.get_faction(Store.get_game_player(fleet.player).faction).color
	for pin in $FleetPins.get_children():
		if pin.color == color:
			return
	add_fleet_pin(color)
		
func add_fleet_pin(color):
	var fleet_pin = system_fleet_pin_scene.instance()
	fleet_pin.color = color
	$FleetPins.add_child(fleet_pin)

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.is_pressed():
		if event.get_button_index() == BUTTON_LEFT:
			Store.select_system(system)
		elif event.get_button_index() == BUTTON_RIGHT && Store._state.selected_fleet != null && Store._state.selected_fleet.system.id != system.id:
			# you can't set the same destination as the origine
			$HTTPRequest.connect("request_completed", self, "_on_fleet_send")
			$HTTPRequest.request(Network.api_url + "/api/games/" + Store._state.game.id + "/systems/+" + Store._state.selected_fleet.system.id + "/fleets/" + Store._state.selected_fleet.id + "/travel/", [
				"Authorization: Bearer " + Network.token
			], false, HTTPClient.METHOD_POST,JSON.print({
				"destination_system_id": system.id,
			}))

func _on_fleet_send(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
		return
	$HTTPRequest.disconnect("request_completed", self, "_on_fleet_send")
	Store._state.selected_fleet.system_arival_id = system.id
	Store.emit_signal("FleetSailed",Store._state.selected_fleet)
	Store.unselect_fleet()

func _on_mouse_entered():
	is_hover = true
	$Star.set_scale(Vector2(scale_ratio * 2, scale_ratio * 2))
	
func _on_mouse_exited():
	is_hover = false
	if system.player != Store._state.player.id && system != Store._state.selected_system:
		$Star.set_scale(Vector2(scale_ratio, scale_ratio))
