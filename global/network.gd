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
	CLIENT_DISCONNECTED,
}

var client = HTTPClient.new()
# the pool of requests to the server
var requests = []
# the next function we need to call whenever the last request resolves
var pending_request = null
# the processing response body
var processed_body = PoolByteArray()

func connect_to_host():
	self.client.connect_to_host("%s://%s" % [Config.api.scheme, Config.api.dns], Config.api.port)
	
func _ready():	
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
	#set_process(false)

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
				var response_code = self.client.get_response_code()
				var response_headers = self.client.get_response_headers_as_dictionary()
				self.trigger_handler(
					null,
					response_code,
					response_headers,
					self.processed_body
				)

			# Process next request if there is place
			if not self.pending_request and not self.requests.empty():
				self.pending_request = self.requests.pop_front()
				self.launch_pending_request()
		HTTPClient.STATUS_CONNECTION_ERROR:
			# reconnect to the server
			self.connect_to_host()
			# if we had a pending request, push it in front of the others
			# it will be handled first
			if self.pending_request:
				self.requests.push_front(self.pending_request)
				self.cleanup_request_state()
		# for every other status
		var other:
			# get the error code corresponding to the status
			# It can be OK, because we handle status like "CONNECTING" or "REQUESTING"
			var err = self.http_client_status_to_error(other)
			# of it IS a bad status, flush the requests and trigger their
			# handlers with an error code
			if err != OK:
				if self.pending_request:
					self.trigger_handler(err, null, null, null)
				while not self.requests.empty():
					self.pending_request = self.requests.pop_front()
					self.launch_pending_request()

# Helper function used only to clear the state of the HTTPClient.
# This "cleanup" code is in a function in order to do the exact same cleanup
# procedure each time we need to.
func cleanup_request_state():
	self.processed_body.resize(0)
	self.pending_request = null

# Use this function to make an HTTP Request instead of the standard "request" method.
func req(calling_object, method_to_trigger, route, method = HTTPClient.METHOD_GET, headers=PoolStringArray(), body="", params=[]):
	self.requests.push_back([method, route, headers, body, calling_object, method_to_trigger, params])

# This function tries to launch the request stored in self.pending_request
# If it cannot (request() returning non-OK value) it triggers the handler
# with the returned error.
func launch_pending_request():
	var headers = self.pending_request[2]
	headers.append("Authorization: Bearer %s" % self.token)
	var err = self.client.request(self.pending_request[0], self.pending_request[1], headers, self.pending_request[3])
	if err != OK:
		self.trigger_handler(err, null, null, null)

func trigger_handler(res_code, http_code, headers, body):
	# call the listener of the pending request
	var f = funcref(self.pending_request[4], self.pending_request[5])
	f.call_funcv([res_code, http_code, headers, body] + self.pending_request[6])
	
	# clean the state to be able to send another request
	self.cleanup_request_state()

# Translate an HTTPClient status value to an Error value.
# This is used to check if a blocking error occurred or not.
func http_client_status_to_error(status):
	var error_dict = {
		HTTPClient.STATUS_CANT_RESOLVE : ERR_CANT_RESOLVE,
		HTTPClient.STATUS_CANT_CONNECT : ERR_CANT_CONNECT,
		HTTPClient.STATUS_SSL_HANDSHAKE_ERROR : ERR_CANT_CONNECT,
	}
	
	return error_dict.get(status, OK)
