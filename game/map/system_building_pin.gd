extends TextureRect

const _ALPHA_SPEED_GAIN = 2.0
const _SNAP_ALPHA_DISTANCE = 0.05
const _ALPHA_APLITUDE = 0.4
const _BLICKING_FREQUENCY = 0.25
const ASSETS = preload("res://resources/assets.tres")

export(Resource) var building = null setget set_building
export(Color, RGB) var faction_color = Color(1.0, 1.0, 1.0) setget set_faction_color
export(bool) var blinking = false setget set_blinking

var _alpha = 1.0

func _ready():
	_updates_elements()


func _process(delta):
	_process_alpha(delta)


func _process_alpha(delta):
	var target_alpha = 1.0
	if blinking:
		target_alpha = cos(OS.get_ticks_msec() as float / 1000.0 * 2.0 * PI * _BLICKING_FREQUENCY) * _ALPHA_APLITUDE + (1.0 - _ALPHA_APLITUDE)
	if not is_equal_approx(_alpha, target_alpha):
		_alpha = clamp((target_alpha - _alpha) * _ALPHA_SPEED_GAIN * delta + _alpha, 0.0, 1.0)
		if abs(target_alpha - _alpha) < _SNAP_ALPHA_DISTANCE:
			_alpha = target_alpha
		_updates_color(_alpha)
	elif not blinking:
		set_process(false)


func set_building(new_type):
	building = new_type
	_updates_elements()


func set_blinking(new_bool):
	blinking = new_bool
	if blinking:
		set_process(true)


func set_faction_color(new_color):
	faction_color = new_color
	_updates_color()


func _updates_elements():
	_update_texture()
	_updates_color()


func _update_texture():
	texture = building.kind.texture if building != null else ASSETS.buildings[""].texture


func _updates_color(alpha = _alpha):
	var color : Color = faction_color if building != null and building.status == "operational" else Color(1.0, 1.0, 1.0)
	color.a = alpha
	modulate = color
