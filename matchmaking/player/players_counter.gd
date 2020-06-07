extends HBoxContainer

var counter = 1;

func _ready():
	Network.req(self, "_on_request_completed", "/api/players/count/")
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

func _on_request_completed(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
		return
	counter = JSON.parse(body.get_string_from_utf8()).result.nb_players
	update_counter()
