extends HTTPRequest

var api_url = null
var websocket_url = null
var _ws_client = WebSocketClient.new()
var token = null

signal authenticated
signal LobbyCreated(lobby)
signal LobbyUpdated(lobby)
signal LobbyNameUpdated(data)
signal LobbyRemoved(lobby)
signal PlayerConnected(player)
signal PlayerDisconnected(player)
signal PlayerUpdate(player)
signal PlayerJoined(player)
signal PlayerLeft(player)

func _ready():
	api_url = Config.api.scheme + "://" + Config.api.dns + ":" + str(Config.api.port)
	websocket_url = Config.api.ws_scheme + "://" + Config.api.dns + ":" + str(Config.api.port) + "/ws/"
	
	_ws_client.connect("connection_closed", self, "_closed")
	_ws_client.connect("connection_error", self, "_closed")
	_ws_client.connect("connection_established", self, "_connected")
	_ws_client.connect("data_received", self, "_on_data")
	self.connect("request_completed", self, "confirm_auth")
	auth()
	
func auth():
	request(api_url + "/login", [], false, HTTPClient.METHOD_POST)
	
func confirm_auth(result, response_code, headers, body):
	token = JSON.parse(body.get_string_from_utf8()).result.token
	connect_ws()
	self.connect("request_completed", self, "set_current_player")
	request(api_url + "/api/players/me/", [
		"Authorization: Bearer " + token
	], false, HTTPClient.METHOD_GET)
	emit_signal("authenticated")
	
func set_current_player(result, response_code, headers, body):
	Store._state.player = JSON.parse(body.get_string_from_utf8()).result
	
func connect_ws():
	# Initiate connection to the given URL.
	var err = _ws_client.connect_to_url(websocket_url, [], false, ["Authorization: Bearer " + token])
	if err != OK:
		print("Unable to connect")
		set_process(false)
		
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
	_ws_client.get_peer(1).put_packet("Test packet".to_utf8())

func _on_data():
	var data = JSON.parse(_ws_client.get_peer(1).get_packet().get_string_from_utf8()).result
	
	print("received data from server: ", data.action)
	
	emit_signal(data.action, data.data)

func _process(delta):
	# Call this in _process or _physics_process. Data transfer, and signals
	# emission will only happen when calling this function.
	_ws_client.poll()
