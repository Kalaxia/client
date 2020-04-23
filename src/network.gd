extends HTTPRequest

var api_dns = "127.0.0.1"
var api_port = 8080
var api_url = "http://" + api_dns + ":" + str(api_port)
var websocket_url = "ws://" + api_dns + ":" + str(api_port) + "/ws/"
var _ws_client = WebSocketClient.new()
var token = null

signal authenticated

func _ready():
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
	emit_signal("authenticated")
	
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
	# Print the received packet, you MUST always use get_peer(1).get_packet
	# to receive data from server, and not get_packet directly when not
	# using the MultiplayerAPI.
	print("Got data from server: ", _ws_client.get_peer(1).get_packet().get_string_from_utf8())

func _process(delta):
	# Call this in _process or _physics_process. Data transfer, and signals
	# emission will only happen when calling this function.
	_ws_client.poll()
