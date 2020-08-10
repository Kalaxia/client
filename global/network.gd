extends Node

signal authenticated()
signal CombatEnded(data)
signal LobbyCreated(lobby)
signal LobbyUpdated(lobby)
signal LobbyOwnerUpdated(data)
signal LobbyNameUpdated(data)
signal LobbyRemoved(lobby)
signal LobbyLaunched(launchData)
signal GameStarted(data)
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
signal SystemsCreated(data)
signal Victory(data)
signal FactionPointsUpdated(scores)
signal ShipQueueFinished(ship_group)
signal BuildingConstructed(building)
signal LobbyOptionsUpdated(lobby)

const MAX_CO_RETRIES = 5
const TIME_BEFORE_CLOSE = 2.0

var api_url = null
var websocket_url = null
var token = null
var _ws_client = WebSocketClient.new()

#
# Everything related to HTTP requests
# 

var client = HTTPClient.new()
# the pool of requests to the server
var requests = []
# the next function we need to call whenever the last request resolves
var pending_request = null
# the processing response body
var processed_body = PoolByteArray()
var old_status = 99
var nb_connection_try = 0
var waiting_for_request = TIME_BEFORE_CLOSE


func connect_to_host():
	var uri = "{scheme}://{dns}".format(Config.api)
	self.client.connect_to_host(uri, Config.api.port)


func _ready():
	api_url = "{scheme}://{dns}:{port}".format(Config.api)
	websocket_url = "{ws_scheme}://{dns}:{port}/ws/".format(Config.api)
	self.client.close()
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
		print(tr("network.unable_connect"))
		set_process(false)


func _closed(was_clean = false):
	# was_clean will tell you if the disconnection was correctly notified
	# by the remote peer before closing the socket.
	print(tr("network.close_clean_ws"), was_clean)
	set_process(false)


func _connected(proto = ""):
	# This is called on connection, "proto" will be the selected WebSocket
	# sub-protocol (which is optional)
	print(tr("Connected with protocol: "), proto)
	# You MUST always use get_peer(1).put_packet to send data to server,
	# and not put_packet directly when not using the MultiplayerAPI.
	_ws_client.get_peer(1).put_packet("Test packet".to_utf8())


func _on_data():
	var data = JSON.parse(_ws_client.get_peer(1).get_packet().get_string_from_utf8()).result
	
	print(tr("received data from server: "), data.action)
	
	emit_signal(data.action, data.data)


func _process(delta):
	# handle WebSoocketClient life
	_ws_client.poll()
	
	# handle HTTPClient life
	self.client.poll()
	var status = self.client.get_status()
	if self.old_status != status:
		print("[HTTP] Status: ", status)
		self.old_status = status

	match status:
		HTTPClient.STATUS_DISCONNECTED:
			if not self.requests.empty():
				self.nb_connection_try += 1
				print("[HTTP] connection try number ", self.nb_connection_try)
				if self.nb_connection_try < MAX_CO_RETRIES:
					self.connect_to_host()
				else:
					self.pending_request = self.requests.pop_front()
					self.launch_pending_request()
		# whenever the http client has a body to fetch, fetch it
		HTTPClient.STATUS_BODY:
			self.processed_body.append_array(self.client.read_response_body_chunk())
		# this is the default status, after we managed to connect to the host
		HTTPClient.STATUS_CONNECTED:
			self.nb_connection_try = 0
			# if the client has a response while having status "CONNECTED"
			# it means the whole response was received and its handler needs
			# to be triggered
			if self.client.has_response():
				print("[HTTP] response received, processing handler")
				var response_code = self.client.get_response_code()
				var response_headers = self.client.get_response_headers_as_dictionary()
				self.trigger_handler(
					null,
					response_code,
					response_headers,
					self.processed_body
				)

			if self.requests.empty():
				self.waiting_for_request -= delta
				if self.waiting_for_request < 0:
					self.client.close()
			else:
				self.waiting_for_request = TIME_BEFORE_CLOSE
				print("[HTTP] requests are waiting, process one")
				self.pending_request = self.requests.pop_front()
				self.launch_pending_request()
		# for every other status
		var other:
			# get the error code corresponding to the status
			# It can be OK, because we handle status like "CONNECTING" or "REQUESTING"
			var err = self.http_client_status_to_error(other)
			# of it IS a bad status, flush the requests and trigger their
			# handlers with an error code
			if err != OK:
				self.client.close()
				if self.pending_request:
					self.trigger_handler(err, null, null, null)


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
	if http_code != null and http_code >= 400:
		print_debug(self.pending_request[1] + " - " + http_code as String + " : " + body.get_string_from_utf8() + ", " + JSON.print(headers))
	# call the listener of the pending request
	var f = funcref(self.pending_request[4], self.pending_request[5])
	if f.is_valid():
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
		HTTPClient.STATUS_CONNECTION_ERROR : ERR_CANT_CONNECT,
	}
	
	return error_dict.get(status, OK)


func extract_pagination_data(content_range):
	var data = content_range.split(" ")[1].split("/")
	var r = data[0].split("-")
	var limit = int(r[1]) - int(r[0])
	
	return {
		"count": int(data[1]),
		"limit": limit,
		"page": int(floor(int(r[0]) / limit)) + 1,
	}
