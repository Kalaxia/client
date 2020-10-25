extends Node2D

const _SCALE_CURRENT_PLAYER_FACTOR = 1.0
const BASE_SCALE = 0.75

var origin_position = Vector2.ZERO
var destination_position = Vector2.ZERO
var fleet : Fleet = null setget set_fleet
var _game_data : GameData = Store.game_data

onready var rotation_conatiner = $FleetPath/Follower/RotationContainer
onready var sprite_container = $FleetPath/Follower/RotationContainer/SpritesContainer
onready var sprite_crown = $FleetPath/Follower/RotationContainer/SpritesContainer/CrownSprite
onready var fleet_sprite = $FleetPath/Follower/RotationContainer/SpritesContainer/FleetIcon
onready var avatar = $FleetPath/Follower/PlayerAvatar
onready var timer_avatar = $FleetPath/Follower/PlayerAvatar/Timer
onready var animation_avatar = $FleetPath/Follower/PlayerAvatar/AnimationPlayer
onready var controle_hover = $FleetPath/Follower/RotationContainer/ControlHover
onready var reference_frame_hover = $FleetPath/Follower/RotationContainer/ControlHover/ReferenceRect
onready var _time_departure = OS.get_system_time_msecs()


func _ready():
	timer_avatar.connect("timeout", self, "_on_timeout_avatar")
	controle_hover.connect("mouse_entered", self, "_on_mouse_enter")
	controle_hover.connect("mouse_exited", self, "_on_mouse_exited")
	Config.config_environment.connect("show_debug_frame_changed", self, "_on_show_debug_frame_changed")
	var curve = Curve2D.new()
	curve.add_point(origin_position)
	curve.add_point(destination_position)
	rotation_conatiner.rotation = (destination_position - origin_position).angle() + PI / 2.0
	$FleetPath.curve = curve
	var color = _game_data.get_player_color(_game_data.get_player(fleet.player))
	sprite_container.set_modulate(color)
	_set_size_sprite()
	_set_icone_texture()
	_set_crown_state()
	_set_avatar()
	_update_show_frame()
	update()


func _draw():
	if Config.config_environment.show_debug_frame:
		draw_polyline($FleetPath.curve.get_baked_points(), Color(0.0, 1.0, 0.0), 1.0)


func _process(_delta):
	$FleetPath/Follower.unit_offset = _get_flight_ratio()


func set_fleet(new_fleet):
	fleet = new_fleet
	_set_size_sprite()
	_set_avatar()


func _set_size_sprite():
	if fleet != null and rotation_conatiner != null:
		var scale_sprite = _SCALE_CURRENT_PLAYER_FACTOR if _game_data.does_belong_to_current_player(fleet) else 1.0
		rotation_conatiner.scale = Vector2(BASE_SCALE * scale_sprite, BASE_SCALE * scale_sprite)


func _get_flight_time_ms():
	# it is possible that fleet.destination_arrival_date is set to null before this objet is freed (because of queue_free) can call _process
	return (fleet.destination_arrival_date - _time_departure) if fleet.destination_arrival_date != null else 0


func _get_flight_ratio():
	return ((OS.get_system_time_msecs() - _time_departure) as float / _get_flight_time_ms() as float) if _get_flight_time_ms() != 0 else 1.0


func _set_icone_texture():
	fleet_sprite.faction = _game_data.get_player(fleet.player).faction


func _set_crown_state():
	var is_current_player = (fleet.player == _game_data.player.id)
	sprite_crown.visible = is_current_player
	if is_current_player:
		sprite_crown.faction = _game_data.get_player(fleet.player).faction


func _on_timeout_avatar():
	animation_avatar.play("fade", -1 , -1.0, not animation_avatar.is_playing())


func _on_mouse_enter():
	if timer_avatar.is_stopped():
		animation_avatar.play("fade", -1 , 1.0, false)
	else:
		timer_avatar.stop()


func _on_mouse_exited():
	timer_avatar.start()


func _set_avatar():
	if avatar != null:
		avatar.player = _game_data.get_player(fleet.player)


func _update_show_frame():
	if reference_frame_hover != null:
		reference_frame_hover.editor_only = not Config.config_environment.show_debug_frame


func _on_show_debug_frame_changed():
	_update_show_frame()
	update()
