extends VBoxContainer

var faction = null
var victory_points = 0
var banners = {
	"Kalankar": preload("res://resources/assets/2d/faction/kalankar/banner.png"),
	"Valkar": preload("res://resources/assets/2d/faction/valkar/banner.png"),
	"Adranite": preload("res://resources/assets/2d/faction/adranite/banner.png"),
}

func _ready():
	$Name.set_text(tr(faction.name))
	$NbSystems.set_text(tr("game.faction_score.victory_points") % victory_points)
	$Banner.set_texture(banners[faction.name])
