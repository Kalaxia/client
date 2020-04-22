extends Control

# The URL we will connect to
export var websocket_url = "ws://echo.websocket.org"

# Our WebSocketClient instance
var _client = WebSocketClient.new()
var lobby_card_scene = preload("res://lobby_card.tscn")
var token = ""

func _ready():
	get_node("Body/Footer/LobbyCreationButton").connect("button_down", self, "create_lobby")
	$HTTPRequest.connect("request_completed", self, "_on_request_completed")
		# Connect base signals to get notified of connection open, close, and errors.
	_client.connect("connection_closed", self, "_closed")
	_client.connect("connection_error", self, "_closed")
	_client.connect("connection_established", self, "_connected")
	# This signal is emitted when not using the Multiplayer API every time
	# a full packet is received.
	# Alternatively, you could check get_peer(1).get_available_packets() in a loop.
	_client.connect("data_received", self, "_on_data")
	auth()
	
func auth():
	$HTTPRequest.request("http://127.0.0.1:8080/login", [], false, HTTPClient.METHOD_POST)
	
func connect_ws():
	# Initiate connection to the given URL.
	var err = _client.connect_to_url(websocket_url)
	if err != OK:
		print("Unable to connect")
		set_process(false)
	
func get_lobbies():
	$HTTPRequest.request("http://127.0.0.1:8080/api/lobbies/", [
		"Authorization: Bearer " + token
	])
	
func create_lobby():
	$HTTPRequest.request("http://127.0.0.1:8080/api/lobbies/", [
		"Authorization: Bearer " + token
	], false, HTTPClient.METHOD_POST)
	
func add_lobby_cards(lobbies):
	for lobby in lobbies:
		add_lobby_card(lobby)
	
func add_lobby_card(lobby):
	var lobby_card = lobby_card_scene.instance()
	lobby_card.lobby = lobby
	get_node("Body/Section/Lobbies").add_child(lobby_card)
	
func _on_request_completed(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8())
	if response_code == 200:
		if json.result.has('token'):
			token = json.result.token
			connect_ws()
			get_lobbies()
		else:
			add_lobby_cards(json.result)
	elif response_code == 201:
		add_lobby_card(json.result)
		
		
func _closed(was_clean = false):
	# was_clean will tell you if the disconnection was correctly notified
	# by the remote peer before closing the socket.
	print("Closed, clean: ", was_clean)
	set_process(false)

func _connected(proto = ""):
	# This is called on connection, "proto" will be the selected WebSocket
	# sub-protocol (which is optional)
	print("Connected with protocol: ", proto)
	# You MUST always use get_peer(1).put_packet to send data to server,
	# and not put_packet directly when not using the MultiplayerAPI.
	_client.get_peer(1).put_packet("Test packet".to_utf8())

func _on_data():
	# Print the received packet, you MUST always use get_peer(1).get_packet
	# to receive data from server, and not get_packet directly when not
	# using the MultiplayerAPI.
	print("Got data from server: ", _client.get_peer(1).get_packet().get_string_from_utf8())

func _process(delta):
	# Call this in _process or _physics_process. Data transfer, and signals
	# emission will only happen when calling this function.
	_client.poll()
