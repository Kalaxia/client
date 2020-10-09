extends Node

const ASSETS = preload("res://resources/assets.tres")

var _rng = RandomNumberGenerator.new()
var _has_already_enter_lobby_auto = false


func _ready():
	_rng.randomize()


func on_loaded_lobby_game_load(main_menu_node, lobby_list):
	if Config.config_environment.debug_activated and Config.config_environment.debug_auto_fill_lobby and not _has_already_enter_lobby_auto:
		_has_already_enter_lobby_auto = true
		if lobby_list.size() > 0:
			main_menu_node.lobbies_container.get_node(lobby_list[0].id).join_lobby()
		else:
			main_menu_node.create_lobby()


func on_lobby_ready(lobby_node):
	if not Config.config_environment.debug_activated or not Config.config_environment.debug_auto_fill_lobby:
		return
	var username = Config.config_user.get_value("Debug", "username", _rng.randi() as String)
	var faction_id = Config.config_user.get_value("Debug", "faction_id", (_rng.randi() % (ASSETS.factions.size() - 1)) + 1)
	var player_info = lobby_node.player_info.get_child(0)
	player_info.faction_choice.selected = faction_id
	player_info.update_faction(faction_id)
	yield(player_info, "player_updated")
	player_info.username_input.text = username # does not work for some reason
	player_info.update_username(username)
	yield(player_info, "player_updated")
	player_info.toggle_ready()
