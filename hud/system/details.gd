extends Control

var banners = {
	"Kalankar": preload("res://resources/assets/2d/faction/kalankar/banner.png"),
	"Valkar": preload("res://resources/assets/2d/faction/valkar/banner.png"),
	"Adranite": preload("res://resources/assets/2d/faction/adranite/banner.png"),
}

func _ready():
	Store.connect("system_selected", self, "_on_system_selected")
	set_visible(false)

func _on_system_selected(system, old_system):
	set_visible(true)
	refresh_data(system)
	
func refresh_data(system):
	if system.player != null:
		var player = Store.get_game_player(system.player)
		$FactionBanner.set_visible(true)
		$FactionBanner.set_texture(banners[Store.get_faction(player.faction).name])
		$Player.set_text(player.username)
		$Player.set_visible(true)
	else:
		$FactionBanner.set_visible(false)
		$Player.set_visible(false)
