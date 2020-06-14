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
	HTTP_TUNNEL_CLOSED,
}

var client = HTTPClient.new()
# the pool of requests to the server
var requests = []
# the next function we need to call whenever the last request resolves
var pending_request = null
# the processing response body
var processed_body = PoolByteArray()
# info from the arriving response
var response_code = null
var response_headers = null

func _handle_co_fail(err):
	if err == FAIL_REASON.HTTP_TUNNEL_CLOSED:
		# we need to reconnect to the host
		self.connect_to_host()
		
		# if we had a pending request, push it in front of the others
		# it will be handled first
		if self.pending_request:
			self.requests.push_front(self.pending_request)
			self.cleanup_request_state()
	# for every other error, recreate the client
	else:
		ErrorHandler.network_response_error(err)
		self.client = HTTPClient.new()

func connect_to_host():
	self.client.connect_to_host(Config.api.scheme + "://" + Config.api.dns, Config.api.port)
	
func _ready():
	self.connect("connection_failed", self, "_handle_co_fail")
	
	api_url = "%s://%s:%d" % [Config.api.scheme, Config.api.dns, Config.api.port]
	websocket_url = "%s://%s:%d/ws/" % [Config.api.ws_scheme, Config.api.dns, Config.api.port]

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
	# handle WebSoocketClient life
	_ws_client.poll()

	# handle HTTPClient life
	self.client.poll()
	match self.client.get_status():
		# whenever the http client has a body to fetch, fetch it
		HTTPClient.STATUS_BODY:
			self.processed_body.append_array(self.client.read_response_body_chunk())
		# this is the default status, after we managed to connect to the host
		HTTPClient.STATUS_CONNECTED:
			# if the client has a response while having status "CONNECTED"
			# it means the whole response was received and its handler needs
			# to be triggered
			if self.client.has_response():
				self.response_code = self.client.get_response_code()
				self.response_headers = self.client.get_response_headers_as_dictionary()
				self._on_server_answer(
					null, # for now it's "null" because i really don't know what to send
					self.response_code,
					self.response_headers,
					self.processed_body
				)
				self.cleanup_request_state()

			# once we managed the hypothetical response, we can send another request
			if not self.requests.empty():
				self.pending_request = self.requests.pop_front()
				self.launch_pending_request()

		HTTPClient.STATUS_SSL_HANDSHAKE_ERROR:
			emit_signal("connection_failed", FAIL_REASON.SSL_HANDSHAKE)
		HTTPClient.STATUS_CONNECTION_ERROR:
			emit_signal("connection_failed", FAIL_REASON.HTTP_TUNNEL_CLOSED)
		HTTPClient.STATUS_CANT_RESOLVE:
			emit_signal("connection_failed", FAIL_REASON.CANNOT_RESOLVE_HOST)
		HTTPClient.STATUS_CANT_CONNECT:
			emit_signal("connection_failed", FAIL_REASON.CANNOT_CONNECT_TO_HOST)
		var other:
			print("NETWORK: WE HAVE AN UNHANDLED STATUS: %d" % other)
			pass

# Helper function used only to clear the state of the HTTPClient.
# This "cleanup" code is in a function in order to do the exact same cleanup
# procedure each time we need to.
func cleanup_request_state():
	self.response_code = null
	self.response_headers = null
	self.processed_body.resize(0)
	self.pending_request = null

# Use this function to make an HTTP Request instead of the standard "request"
# method.
func req(calling_object, method_to_trigger, route, method = HTTPClient.METHOD_GET, headers=PoolStringArray(), body=""):
	self.requests.push_back([method, route, headers, body, calling_object, method_to_trigger])

func launch_pending_request():
	var headers = self.pending_request[2]
	headers.append("Authorization: Bearer %s" % self.token)
	var err = self.client.request(self.pending_request[0], self.pending_request[1], headers, self.pending_request[3])
	if err != OK:
		print("NETWORK: ERROR WHILE REQUESTING API URL: %d" % err)


func _on_server_answer(res_code, http_code, headers, body):
	# call the listener of this particular request
	var f = funcref(self.pending_request[4], self.pending_request[5])
	f.call_func(res_code, http_code, headers, body)

