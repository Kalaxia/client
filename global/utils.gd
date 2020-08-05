extends Object

############## CONSTANTS ##############

const AUDIO_VOLUME_DB_MIN = -100.0 # in dB
const SCALE_SYSTEMS_COORDS = 20
const FLEET_RANGE = 20.0

############## LOCK ##############

class Lock:
	extends Reference
	
	var _is_locked = false setget _private_setter,get_is_locked

	enum LOCK_STATE {
		BUSY = 0,
		OK = 1,
	} # can be used in if directly like they are bools

	enum CAN_LOCK_STATE{
		CANNOT_LOCK = 0,
		CAN_LOCK = 1,
	}

	func _private_setter(variable):
		# cannot be set from outisde
		pass

	func get_is_locked():
		return _is_locked

	func try_lock():
		if _is_locked:
			return LOCK_STATE.BUSY
		_is_locked = true
		return LOCK_STATE.OK

	func unlock():
		_is_locked = false

	func can_lock():
		return CAN_LOCK_STATE.CANNOT_LOCK if _is_locked else CAN_LOCK_STATE.CAN_LOCK

############## METHODS ##############

func get_label_of_event(event):
	if event is InputEventKey:
		return event.as_text()
	if event is InputEventMouseButton:
		return tr("action.key.mouse_key_" + (event.button_index as String))
	return ""

############## STATICS METHODS ##############

static func set_window_resizable(is_resizable):
	var size = OS.window_size
	var position = OS.window_position
	if OS.window_resizable == is_resizable:
		return
	OS.set_window_resizable(is_resizable)
	OS.min_window_size = Vector2(1280,720) if is_resizable else Vector2.ZERO

static func lighten_color(color):
	color.r = min( color.r + 40 / 255.0, 1.0)
	color.g = min( color.g + 40 / 255.0, 1.0)
	color.b = min( color.b + 40 / 255.0, 1.0)
	return color

static func translate_system_kind(server_kind : String) -> String:
	match server_kind:
		"VictorySystem":
			return "system_disk"
		"BaseSystem":
			return "system_circle"
		var x:
			return x
