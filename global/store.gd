extends Node

signal notification_added(notification) # keep

var assets : KalaxiaAssets = preload("res://resources/assets.tres") 
var game_data : GameData = null
var lobby : Lobby = null
var player : Player = null
var victorious_faction : float = 0.0 # todo review


func update_assets(cached_data : CachedResource):
	assets.load_data_from_cached(cached_data)


func notify(title, content):
	# keep (for the moment)
	emit_signal("notification_added", {
		"title": title,
		"content": content
	})
