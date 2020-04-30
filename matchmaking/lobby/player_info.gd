extends PanelContainer

var player = null

# Called when the node enters the scene tree for the first time.
func _ready():
	$Username.set_text(get_username())
	if player.id == Store._state.player.id:
		$HTTPRequest.connect("request_completed", self, "_on_request_completed")
		$UsernameInput.visible = true
		$UsernameInput.connect("text_entered", self, "update_username")
		$Background.color = Color(0,0,0)

func get_username():
	if player.username != '':
		return player.username
	return "Inconnu"
	
func update_username(username):
	player.username = username
	print(JSON.print({ "username": username }))
	$HTTPRequest.request(Network.api_url + "/api/players/me/username", [
		"Content-Type: application/json",
		"Authorization: Bearer " + Network.token
	], false, HTTPClient.METHOD_PATCH, JSON.print({ "username": username }))

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _on_request_completed(result, response_code, headers, body):
	print(response_code)
	$UsernameInput.visible = false
	$Username.set_text(get_username())
