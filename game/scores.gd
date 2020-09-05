extends Control

signal scene_requested(scene)

var game_data = load(GameData.PATH_NAME)

const FACTION_SCORE_SCENE = preload("res://game/faction_score.tscn")


func _ready():
	get_node("Footer/BackToMenu").connect("pressed", self, "_back_to_menu")
	var scores = game_data.scores
	if game_data.player.faction.id == Store.victorious_faction:
		$Label.set_text(tr("game.score.victory"))
	else:
		$Label.set_text(tr("game.score.defeat"))
	for score in scores:
		var faction_score = FACTION_SCORE_SCENE.instance()
		faction_score.score = score.faction
		if score.faction.id == Store.victorious_faction:
			$WinningFaction.add_child(faction_score)
		else:
			$DefeatedFactions.add_child(faction_score)


func _back_to_menu():
	game_data.unload_data()
	emit_signal("scene_requested", "menu")
