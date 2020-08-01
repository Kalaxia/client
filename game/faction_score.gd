extends VBoxContainer

var faction = null setget set_faction
var victory_points = 0 setget set_victory_points


func _ready():
	_update_faction()
	_update_points()


func _update_points():
	$NbSystems.set_text(tr("game.faction_score.victory_points %d") % victory_points)


func _update_faction():
	if faction == null:
		return
	$Name.set_text(tr(faction.name))
	$Banner.set_texture(Utils.BANNERS[faction.id as int])


func set_faction(new_faction):
	faction = new_faction
	_update_faction()


func set_victory_points(points):
	victory_points = points
	_update_points()
