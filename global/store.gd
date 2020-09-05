extends Node

signal notification_added(notification) # keep

#const _STATE_EMPTY = {
#	#"factions": {},
#	"game": {},
#	"lobby": null,
#	"player": null,
#	"selected_system": null,
#	"selected_fleet": null,
#	"scores": {},
#	"victorious_faction": null,
#	#"ship_models" : [],
#	#"building_list" : [],
#}
#
#var _state = _STATE_EMPTY.duplicate(true)
var assets : KalaxiaAssets = preload("res://resources/assets.tres") 
var game_data : GameData = null
var lobby : Lobby = null
var player : Player = null

func update_assets(cached_data : CachedResource):
	assets.load_data_from_cached(cached_data)


func reset_player_lobby_data():
	# ??? 
	lobby.player.ready = false


func notify(title, content):
	# keep (for the moment)
	emit_signal("notification_added", {
		"title": title,
		"content": content
	})
