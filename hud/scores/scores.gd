extends PanelContainer

const SCORE_FACTION = preload("res://hud/scores/score_faction.tscn")

func _ready():
	for faction in Store._state.factions.values():
		var node = SCORE_FACTION.instance()
		node.faction = int(faction.id)
		$container.add_child(node)
