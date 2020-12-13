extends Control

signal scene_requested(scene)

var _game_data = Store.game_data

const FACTION_SCORE_SCENE = preload("res://game/faction_score.tscn")


func _ready():
	print_stack()
	get_node("Footer/BackToMenu").connect("pressed", self, "_back_to_menu")
	var scores = _game_data.scores
	if _game_data.player.faction.id == Store.victorious_faction:
		$Label.set_text(tr("game.score.victory"))
	else:
		$Label.set_text(tr("game.score.defeat"))
	for score in scores.values():
		var faction_score = FACTION_SCORE_SCENE.instance()
		faction_score.score = score
		if score.faction.id == Store.victorious_faction:
			$WinningFaction.add_child(faction_score)
		else:
			$DefeatedFactions.add_child(faction_score)


func _back_to_menu():
	_game_data.unload_data()
	print_stack()
	emit_signal("scene_requested", "menu")
