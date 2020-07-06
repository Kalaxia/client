extends PanelContainer

const SCORE_FACTION = preload("res://hud/scores/score_faction.tscn")

func _ready():
	for i in Store._state.factions.values():
		var node = SCORE_FACTION.instance()
		node.faction = i.id as int
		$container.add_child(node)
