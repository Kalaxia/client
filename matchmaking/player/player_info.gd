extends PanelContainer

signal player_updated(player)

var player = null
var banners = {
	"Kalankar": preload("res://resources/assets/2d/faction/kalankar/banner_image.png"),
	"Valkar": preload("res://resources/assets/2d/faction/valkar/banner_image.png"),
	"Adranite": preload("res://resources/assets/2d/faction/adranite/banner_image.png"),
}

# Called when the node enters the scene tree for the first time.
func _ready():
	var username_input = get_node("Container/UsernameInput")
	username_input.set_text(get_username())
	var ready_input = get_node("Container/ReadyInput")
	ready_input.pressed = player.ready
	init_faction_choices()
	if player.id == Store._state.player.id:
		$Background.color = Color(0,0,0)
		username_input.editable = true
		username_input.connect("text_entered", self, "update_username")
		ready_input.connect("pressed", self, "toggle_ready")
		
func init_faction_choices():
	var faction_choice = get_node("Container/FactionChoice")
	faction_choice.add_item("Faction", 0)
	faction_choice.set_item_disabled(0, true)
	for faction in Store._state.factions.values():
		var image = banners[faction.name]
		var texture = ImageTexture.new()
		texture.create_from_image(image, ImageTexture.FLAG_MIPMAPS | ImageTexture.FLAG_FILTER | ImageTexture.FLAG_ANISOTROPIC_FILTER)
		texture.set_size_override(Vector2(50, 50))
		faction_choice.add_icon_item(texture, faction.name, faction.id)
	if player.id == Store._state.player.id:
		faction_choice.disabled = false
		faction_choice.flat = false
		faction_choice.connect("item_selected", self, "update_faction")
	faction_choice.selected = player.faction if player.faction != null else 0

func get_username():
	if player.username != '':
		return player.username
	return "Inconnu"
	
func update_data(data):
	player = data
	get_node("Container/UsernameInput").set_text(get_username())
	if player.faction != null:
		var faction_choice = get_node("Container/FactionChoice")
		faction_choice.selected = faction_choice.get_item_index(player.faction)
	get_node("Container/ReadyInput").pressed = player.ready
	
func update_username(username):
	Store._state.player.username = username
	Network.req(self, "_on_request_completed"
		, "/api/players/me/username"
		, HTTPClient.METHOD_PATCH
		, [ "Content-Type: application/json" ]
		, JSON.print({ "username": username })
	)

func update_faction(index):
	Store._state.player.faction = get_node("Container/FactionChoice").get_item_id(index)
	Network.req(self, "_on_request_completed"
		, "/api/players/me/faction"
		, HTTPClient.METHOD_PATCH
		, [ "Content-Type: application/json" ]
		, JSON.print({ "faction_id": Store._state.player.faction })
	)
	
func toggle_ready():
	Store._state.player.ready = !player.ready
	Network.req(self, "_on_request_completed"
		, "/api/players/me/ready"
		, HTTPClient.METHOD_PATCH
	)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _on_request_completed(result, response_code, headers, body):
	print("player updated")
	emit_signal("player_updated", Store._state.player)
	if Store._state.player.faction != null && Store._state.player.username != '':
		get_node("Container/ReadyInput").disabled = false
