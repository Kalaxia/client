extends Control

const SCORE_FACTION = preload("res://hud/scores/score_faction.tscn")
const ASSETS = preload("res://resources/assets.tres")


func _ready():
	for faction in ASSETS.factions:
		if faction.id != 0:
			var has_player = false
			for player in Store.game_data.players.values():
				if player.faction.id == faction.id:
					has_player = true
					break
			if has_player:
				var node = SCORE_FACTION.instance()
				node.faction = faction.id
				$Scores.add_child(node)
