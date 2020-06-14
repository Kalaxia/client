extends Node

var api_url = null
var websocket_url = null
var _ws_client = WebSocketClient.new()
var token = null

signal authenticated
signal CombatEnded(data)
signal LobbyCreated(lobby)
signal LobbyUpdated(lobby)
signal LobbyOwnerUpdated(data)
signal LobbyNameUpdated(data)
signal LobbyRemoved(lobby)
signal LobbyLaunched(launchData)
signal GameStarted(game)
signal PlayerConnected(player)
signal PlayerDisconnected(player)
signal PlayerUpdate(player)
signal PlayerJoined(player)
signal PlayerLeft(player)
signal PlayerIncome(data)
signal FleetCreated(fleet)
signal FleetSailed(fleet) 
signal FleetArrived(fleet) 
signal SystemConquerred(data)
signal Victory(data)

#
# Everything related to HTTP requests
# 

signal connection_failed(reason)

enum FAIL_REASON {
	SSL_HANDSHAKE,
	CANNOT_RESOLVE_HOST,
	CANNOT_CONNECT_TO_HOST,
	HTTP_CONNECTION_ERROR,
}

var client = HTTPClient.new()
# the pool of requests to the server
var requests = []
# the next function we need to call whenever the last request resolves
var method_to_trigger = null
# the processing response body
var processed_body = PoolByteArray()

func _handle_co_fail(err):
	if err == FAIL_REASON.HTTP_CONNECTION_ERROR:
		self.connect_to_host()
	else:
		ErrorHandler.network_response_error(err)
		self.client = HTTPClient.new()

func connect_to_host():
	self.client.connect_to_host(Config.api.scheme + "://" + Config.api.dns, Config.api.port)
	
func _ready():
	self.connect("connection_failed", self, "_handle_co_fail")
	
	api_url = Config.api.scheme + "://" + Config.api.dns + ":" + str(Config.api.port)
	websocket_url = Config.api.ws_scheme + "://" + Config.api.dns + ":" + str(Config.api.port) + "/ws/"

	auth()
	
func auth():
	Network.req(self, "confirm_auth", "/login", HTTPClient.METHOD_POST)
	
func confirm_auth(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
		return
	self.token = JSON.parse(body.get_string_from_utf8()).result.token
	connect_ws()
	Network.req(self, "set_current_player", "/api/players/me/")
	emit_signal("authenticated")
	
func set_current_player(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
		return
	Store._state.player = JSON.parse(body.get_string_from_utf8()).result
	
func connect_ws():
	_ws_client.connect("connection_closed", self, "_closed")
	_ws_client.connect("connection_error", self, "_closed")
	_ws_client.connect("connection_established", self, "_connected")
	_ws_client.connect("data_received", self, "_on_data")
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
	_ws_client.poll()

	self.client.poll()
	match self.client.get_status():
		# whenever the http client has a body to fetch, fetch it
		HTTPClient.STATUS_BODY:
			self.processed_body.append_array(self.client.read_response_body_chunk())
			
		# this is the default status, after we managed to connect to the host
		HTTPClient.STATUS_CONNECTED:
			# if we requested something and got a response, process it
			if self.client.has_response():
				self._on_server_answer(
					null, # for now it's "null" because i really don't know what to send
					self.client.get_response_code(),
					self.client.get_response_headers(),
					self.processed_body
				)
				self.processed_body.resize(0)

			# once we managed the hypothetical response, we can send another request
			if not self.requests.empty():
				var data = self.requests.pop_front()
				self.method_to_trigger = data[4]
				var headers = data[2]
				headers.append("Authorization: Bearer " + str(self.token))
				var err = self.client.request(data[0], data[1], headers, data[3])
				if err != OK:
					printerr("ERROR WHILE REQUESTING API URL: " + str(err))
		HTTPClient.STATUS_SSL_HANDSHAKE_ERROR:
			emit_signal("connection_failed", FAIL_REASON.SSL_HANDSHAKE)
		HTTPClient.STATUS_CONNECTION_ERROR:
			emit_signal("connection_failed", FAIL_REASON.HTTP_CONNECTION_ERROR)
		HTTPClient.STATUS_CANT_RESOLVE:
			emit_signal("connection_failed", FAIL_REASON.CANNOT_RESOLVE_HOST)
		HTTPClient.STATUS_CANT_CONNECT:
			emit_signal("connection_failed", FAIL_REASON.CANNOT_CONNECT_TO_HOST)
		var other:
			# printerr("WE HAVE AN UNHANDLED STATUS: " + str(other))
			pass
				

# Use this function to make an HTTP Request instead of the standard "request"
# method.
func req(calling_object, method_to_trigger, route, method = HTTPClient.METHOD_GET, headers=PoolStringArray(), body=""):
	var function = funcref(calling_object, method_to_trigger)
	self.requests.push_back([method, route, headers, body, function])

func _on_server_answer(res_code, http_code, headers, body):
	# call the listener of this particular request
	self.method_to_trigger.call_func(res_code, http_code, headers, body)

