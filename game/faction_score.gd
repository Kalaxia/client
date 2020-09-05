extends VBoxContainer

var score : ScoreFaction = null setget set_score


func _ready():
	_update_faction()
	_update_points()


func _update_points():
	$VictoryPoints.set_text(tr("game.faction_score.victory_points %d") % score.victory_points)


func _update_faction():
	if score.faction == null:
		return
	$Name.set_text(tr(score.faction.name))
	$Banner.set_texture(score.faction.banner)


func set_score(new_score):
	score = new_score
	_update_points()
	_update_faction()
