extends Node

var env = "production"

var api = {
	'dns': null,
	'port': null,
	'scheme': null,
	'ws_scheme': null
}

func _ready():
	var config = ConfigFile.new()
	var err = config.load("res://config/" + env + ".cfg")
	if err == OK:
		api.dns = config.get_value('network', 'api_dns', '127.0.0.1')
		api.port = config.get_value('network', 'api_port', 8080)
		api.scheme = config.get_value('network', 'api_scheme', 'http')
		api.ws_scheme = config.get_value('network', 'ws_scheme', 'ws')
	else:
		print("error while parsing configuration file : " + str(err))
