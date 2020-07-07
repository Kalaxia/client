extends Control

signal scene_requested(scene)

var faction_score_scene = preload("res://game/faction_score.tscn")

func _ready():
	get_node("Footer/BackToMenu").connect("pressed", self, "_back_to_menu")
	var scores = Store._state.scores
	if Store._state.player.faction == Store._state.victorious_faction:
		$Label.set_text(tr("game.score.victory"))
	else:
		$Label.set_text(tr("game.score.defeat"))
	
	for score in scores:
		var fid = float(score.faction)
		var faction = Store.get_faction(fid)
		
		var faction_score = faction_score_scene.instance()
		faction_score.faction = faction
		faction_score.victory_points = score.victory_points
		
		if fid == Store._state.victorious_faction:
			$WinningFaction.add_child(faction_score)
		else:
			$DefeatedFactions.add_child(faction_score)

func _back_to_menu():
	Store.unload_data()
	emit_signal("scene_requested", "menu")
