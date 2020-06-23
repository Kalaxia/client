extends VBoxContainer

var faction = null
var nb_systems = 0
var banners = {
	"Kalankar": preload("res://resources/assets/2d/faction/kalankar/banner.png"),
	"Valkar": preload("res://resources/assets/2d/faction/valkar/banner.png"),
	"Adranite": preload("res://resources/assets/2d/faction/adranite/banner.png"),
}

func _ready():
	$Name.set_text(tr(faction.name))
	$NbSystems.set_text(tr("game.faction_score.number_systems") % nb_systems)
	$Banner.set_texture(banners[faction.name])
