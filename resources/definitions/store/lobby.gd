extends DictResource
class_name Lobby

export(String) var id = null
export(Resource) var owner = null # Player
export(Dictionary) var players = {}
export(Resource) var option = LobbyOption.new()


func _init(dict = null).(dict):
	pass


func load_dict(dict):
	if dict == null:
		return
	.load_dict(dict)
	for player in dict.players:
		players[player.id] = Player.new(player)
	if not dict is Dictionary or dict.has("owner"):
		owner = Player.new(dict.owner)
	option = LobbyOption.new(dict)


func _get_dict_property_list():
	return ["id"]
