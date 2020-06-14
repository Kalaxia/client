extends HBoxContainer

var counter = 1 setget set_counter, get_counter;

func _ready():
	Network.req(self, "_on_request_completed", "/api/players/count/")
	Network.connect("PlayerConnected", self, "increment_counter")
	Network.connect("PlayerDisconnected", self, "decrement_counter")

func set_counter(c):
	counter = c
	$Counter.set_text(str(counter))

func get_counter():
	return counter

func increment_counter(player):
	self.counter = counter + 1
	
func decrement_counter(player):
	self.counter = counter - 1

func _on_request_completed(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
		return
	self.counter = JSON.parse(body.get_string_from_utf8()).result.nb_players
