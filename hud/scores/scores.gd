extends PanelContainer

const SCORE_FACTION = preload("res://hud/scores/score_faction.tscn")
const ASSETS = preload("res://resources/assets.tres")


func _ready():
	for faction in ASSETS.factions:
		var node = SCORE_FACTION.instance()
		node.faction = int(faction.id)
		$Container/Scores.add_child(node)
