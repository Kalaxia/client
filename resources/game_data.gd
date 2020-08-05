extends Resource
class_name GameData

export var id : String
export var systems : Dictionary
export var players : Dictionary

func _init(p_id : String) -> void:
	self.id = p_id

func insert_system(p_system : Dictionary) -> void:
	var SysData = load("res://resources/system_data.gd")
	var new_system = SysData.new()
	new_system.load_dict(p_system)
	
	self.systems[p_system.id] = new_system
	emit_signal("changed")

func insert_player(p_player : Dictionary) -> void:
	var new_player = PlayerData.new()
	new_player.load_dict(p_player)
	
	self.players[p_player] = new_player
	emit_signal("changed")
