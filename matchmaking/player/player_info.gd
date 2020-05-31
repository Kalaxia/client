extends PanelContainer

var player = null

signal player_updated(player)

# Called when the node enters the scene tree for the first time.
func _ready():
	var username_input = get_node("Container/UsernameInput")
	username_input.set_text(get_username())
	var faction_choice = get_node("Container/FactionChoice")
	faction_choice.selected = player.faction if player.faction != null else 0
	var ready_input = get_node("Container/ReadyInput")
	ready_input.pressed = player.ready
	if player.id == Store._state.player.id:
		$HTTPRequest.connect("request_completed", self, "_on_request_completed")
		$Background.color = Color(0,0,0)
		username_input.editable = true
		username_input.connect("text_entered", self, "update_username")
		faction_choice.disabled = false
		faction_choice.flat = false
		faction_choice.connect("item_selected", self, "update_faction")
		ready_input.connect("pressed", self, "toggle_ready")

func get_username():
	if player.username != '':
		return player.username
	return "Inconnu"
	
func update_data(data):
	player = data
	get_node("Container/UsernameInput").set_text(get_username())
	if player.faction != null:
		get_node("Container/FactionChoice").selected = player.faction
	get_node("Container/ReadyInput").pressed = player.ready
	
func update_username(username):
	Store._state.player.username = username
	$HTTPRequest.request(Network.api_url + "/api/players/me/username", [
		"Content-Type: application/json",
		"Authorization: Bearer " + Network.token
	], false, HTTPClient.METHOD_PATCH, JSON.print({ "username": username }))

func update_faction(faction_id):
	Store._state.player.faction = faction_id
	$HTTPRequest.request(Network.api_url + "/api/players/me/faction", [
		"Content-Type: application/json",
		"Authorization: Bearer " + Network.token
	], false, HTTPClient.METHOD_PATCH, JSON.print({ "faction_id": faction_id }))
	
func toggle_ready():
	Store._state.player.ready = !player.ready
	$HTTPRequest.request(Network.api_url + "/api/players/me/ready", [
		"Authorization: Bearer " + Network.token
	], false, HTTPClient.METHOD_PATCH)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _on_request_completed(result, response_code, headers, body):
	emit_signal("player_updated", Store._state.player)
	if Store._state.player.faction != null && Store._state.player.username != '':
		get_node("Container/ReadyInput").disabled = false
