extends Node


class Lock:
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
	
