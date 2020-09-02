extends Resource
class_name GameData

export(String) var id
export(Dictionary) var systems
export(Dictionary) var players


func _init(p_id : String) -> void:
	self.id = p_id


func insert_system(p_system : Dictionary) -> void:
	var new_system = System.new(p_system)
	self.systems[p_system.id] = new_system
	emit_signal("changed")


func insert_player(p_player : Dictionary) -> void:
	self.players[p_player] = Player.new(p_player)
	emit_signal("changed")
