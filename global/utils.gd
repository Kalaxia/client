extends Node

const AUDIO_VOLUME_DB_MIN = -100.0 # in dB
const MAX_BUS_TO_SCAN = 20

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

func _ready():
	pass # Replace with function body.

func get_label_of_event(event):
	if event is InputEventKey:
		return event.as_text()
	if event is InputEventMouseButton:
		return tr("action.key.mouse_key_" + (event.button_index as String))
	return ""
