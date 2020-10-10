extends Control

const _SCALE_CURRENT_PLAYER_FACTOR = 1.5

var faction : KalaxiaFaction = null
var is_current_player = false
var color = null

onready var sprites_container = $SpritesContainer
onready var fleet_sprite = $SpritesContainer/Fleet
onready var crown = $SpritesContainer/CrownSprite


func _ready():
	_set_pin_texture()
	sprites_container.set_modulate(color)
	crown.visible = is_current_player
	if is_current_player:
		sprites_container.set_scale(Vector2(_SCALE_CURRENT_PLAYER_FACTOR,_SCALE_CURRENT_PLAYER_FACTOR))


func _set_pin_texture():
	fleet_sprite.faction = faction
	if is_current_player:
		crown.faction = faction
