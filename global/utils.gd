extends Object
class_name Utils

############## CONSTANTS ##############

const AUDIO_VOLUME_DB_MIN = -100.0 # in dB
const SCALE_SYSTEMS_COORDS = 20

############## LOCK ##############

class Lock:
	extends Reference
	
	signal locked()
	signal unlocked()
	signal changed_state(lock_state)
	
	enum LOCK_STATE {
		BUSY = 0,
		OK = 1,
	} # can be used in if directly like they are bools
	enum CAN_LOCK_STATE{
		CANNOT_LOCK = 0,
		CAN_LOCK = 1,
	}
	
	var _is_locked = false setget _private_setter, get_is_locked
	
	
	func _private_setter(_variable):
		# cannot be set from outisde
		pass
	
	
	func get_is_locked():
		return _is_locked
	
	
	func try_lock():
		if _is_locked:
			return LOCK_STATE.BUSY
		_is_locked = true
		emit_signal("locked")
		emit_signal("changed_state", true)
		return LOCK_STATE.OK
	
	
	func unlock():
		var previous_state = _is_locked
		_is_locked = false
		if previous_state:
			emit_signal("unlocked")
			emit_signal("changed_state", false)
		return previous_state
	
	
	func can_lock():
		return CAN_LOCK_STATE.CANNOT_LOCK if _is_locked else CAN_LOCK_STATE.CAN_LOCK

############## METHODS ##############

func _init():
	push_error("Utils is not meant to be initialised")
	assert(false)

############## STATICS METHODS ##############


static func get_label_of_event(event):
	if event is InputEventKey:
		return event.as_text()
	if event is InputEventMouseButton:
		return TranslationServer.translate("action.key.mouse_key_" + (event.button_index as String))
	return ""


static func set_window_resizable(is_resizable):
	if OS.window_resizable == is_resizable:
		return
	OS.set_window_resizable(is_resizable)
	OS.min_window_size = Vector2(1280, 720) if is_resizable else Vector2.ZERO


static func lighten_color(color):
	color.r = min(color.r + 40.0 / 255.0, 1.0)
	color.g = min(color.g + 40.0 / 255.0, 1.0)
	color.b = min(color.b + 40.0 / 255.0, 1.0)
	return color


static func translate_system_kind(server_kind : String) -> String:
	match server_kind:
		"VictorySystem":
			return "system_disk"
		"BaseSystem":
			return "system_circle"
		var x:
			return x


static func capitalise_first_letter(string: String) -> String:
	return string.left(1).to_upper() + string.substr(1)


static func trim(string: String) -> String:
	# todo improve
	return string.replace("  ", " ").trim_prefix(" ").trim_suffix(" ")


static func int_min(a: int, b: int) -> int:
	if a < b:
		return a
	else:
		return b


static func int_max(a: int, b: int) -> int:
	if a > b:
		return a
	else:
		return b
