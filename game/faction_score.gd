extends VBoxContainer

var faction = null
var victory_points = 0

const assets = preload("res://resources/assets.tres")

func _ready():
	$Name.set_text(tr(faction.name))
	$NbSystems.set_text(tr("game.faction_score.victory_points") % victory_points)
	$Banner.set_texture(assets.factions[faction].banner)
