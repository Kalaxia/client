extends VBoxContainer

var faction = null
var nb_systems = 0
var banners = {
	"Kalankar": preload("res://resources/assets/2d/faction/kalankar/banner.png"),
	"Valkar": preload("res://resources/assets/2d/faction/valkar/banner.png"),
	"Adranite": preload("res://resources/assets/2d/faction/adranite/banner.png"),
}

func _ready():
	$Name.set_text(faction.name)
	$NbSystems.set_text(str(nb_systems) + " systèmes contrôlés")
	$Banner.set_texture(banners[faction.name])
