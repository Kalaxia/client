class_name Lobby
extends DictResource

signal player_removed(player_id)

export(String) var id = null
export(Resource) var owner = null # Player
export(Dictionary) var players
export(Resource) var option = null #= LobbyOption.new()


func _init(dict = null, player : Player = null).(dict):
	if player:
		relink_player(player)


func load_dict(dict):
	if dict == null:
		return
	.load_dict(dict)
	if (not dict is Dictionary or dict.has("players")) and dict.players != null:
		players.clear()
		for player in dict.players:
			players[player.id] = Player.new({"id" : player} if player is String else player)
	if not dict is Dictionary or dict.has("owner"):
		owner = Player.new({"id" : dict.owner} if dict.owner is String else dict.owner)
		players[owner.id] = owner # relink owner to the array of player
	if option == null:
		option = LobbyOption.new(dict)
	else:
		option.load_dict(dict)


func _get_dict_property_list() -> Array:
	return ["id"]


func update(dict : Dictionary, player : Player):
	load_dict(dict)
	relink_player(player)


func relink_player(player : Player):
	if player == null:
		return
	players[player.id] = player
	if owner.id == player.id:
		owner = player


func get_name() -> String:
	return get_lobby_name(self)


func get_player(pid) -> Player:
	if not pid is String and not (pid is Dictionary and pid.has("id")):
		return null
	for p in players.values():
		if (pid is String and p.id == pid) or (pid is Dictionary and pid.id == p.id):
			return p
	return null


func remove_player_lobby(player_id : String) -> bool:
	var is_erased = players.erase(player_id)
	if is_erased:
		print_stack()
		emit_signal("player_removed", player_id)
	return is_erased


static func get_lobby_name(lobby) -> String:
	return TranslationServer.translate("store.game_of %s") % lobby.owner.username \
			if lobby.owner != null and lobby.owner.username != "" \
			else TranslationServer.translate("store.new_game")
