extends Control

var lobby_scene = load("res://menu/menu_screen.tscn")
# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("Body/Header/Name").set_text(Store._state.lobby.id)
	get_node("Body/Footer/LeaveButton").connect("pressed", self, "leave_lobby")
	$HTTPRequest.connect("request_completed", self, "_on_request_completed")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func leave_lobby():
	$HTTPRequest.request(Network.api_url + "/api/lobbies/" + Store._state.lobby.id + "/players/", [
		"Authorization: Bearer " + Network.token
	], false, HTTPClient.METHOD_DELETE)

func _on_request_completed(result, response_code, headers, body):
	print(response_code)
	print(headers)
	print(result)
	get_tree().change_scene_to(lobby_scene)
	
