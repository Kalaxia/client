class_name FSMEvent
extends Reference

export(String) var event_name = ""
export(Array) var variant_array = []


func _init(event_name_new = "", variant_array_new = []):
	._init()
	event_name = event_name_new
	variant_array = variant_array_new
