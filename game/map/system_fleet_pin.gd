extends Control

var faction = null
var is_current_player = false
var color = null

const _SCALE_CURRENT_PLAYER_FACTOR = 1.0

func _ready():
	_set_pin_texture()
	$SpritesContainer.set_modulate(color)
	$SpritesContainer/CrownSprite.visible = is_current_player
	if is_current_player:
		$SpritesContainer.set_scale(Vector2(_SCALE_CURRENT_PLAYER_FACTOR,_SCALE_CURRENT_PLAYER_FACTOR))

func _set_pin_texture():
	$SpritesContainer/Fleet.faction = faction
	$SpritesContainer/Fleet.set_faction_texture()
	if is_current_player:
		$SpritesContainer/CrownSprite.faction = faction
		$SpritesContainer/CrownSprite.set_faction_texture()
