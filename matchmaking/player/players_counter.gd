extends HBoxContainer

var counter = 1;

func _ready():
	$HTTPRequest.connect("request_completed", self, "_on_request_completed")
	$HTTPRequest.request(Network.api_url + "/api/players/count/")
	Network.connect("PlayerConnected", self, "increment_counter")
	Network.connect("PlayerDisconnected", self, "decrement_counter")

func increment_counter(player):
	counter = counter + 1
	update_counter()
	
func decrement_counter(player):
	counter = counter - 1
	update_counter()

func update_counter():
	$Counter.set_text(str(counter))

func _on_request_completed(result, response_code, headers, body):
	counter = JSON.parse(body.get_string_from_utf8()).result.nb_players + 1
	update_counter()
