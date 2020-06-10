extends Control

var faction = null
var is_current_player = false
var color = null

func _ready():
	_set_pin_texture()
	$SpritesContainer.set_modulate(color)
	if is_current_player:
		$SpritesContainer.set_scale(Vector2(1.5,1.5))

func _set_pin_texture():
	$SpritesContainer/Fleet.faction = faction
	$SpritesContainer/Fleet.set_faction_texture()
