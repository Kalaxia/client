extends Control

var _time = 0.0
const TIME_LOADING = 5.0
const COLOR_ATTENUATION = 3.0

signal scene_requested(scene)

func _ready():
	Network.connect("GameStarted", self, "_on_game_started")
	Network.req(self, "_on_players_loaded", "/api/games/" + Store._state.game.id + "/players/")
	var forground = get_node("CenterContainer/VBoxContainer/ProgressBar").get("custom_styles/fg")
	var faction = Store.get_faction(float(Store._state.player.faction))
	# if this does not work you may have a type problem for the keys of the Store._state.faction 
	forground.set_bg_color(Color(faction.color[0]/255.0 / COLOR_ATTENUATION,faction.color[1]/255 /COLOR_ATTENUATION,faction.color[2]/255.0 / COLOR_ATTENUATION))

func _process(delta):
	_time += delta
	get_node("CenterContainer/VBoxContainer/ProgressBar").set_value(min(_time/TIME_LOADING*100.0,99.99))

func _on_game_started(game):
	Store._state.game.systems = game.systems
	Store._state.player.wallet = 0
	emit_signal("scene_requested", "game")

func _on_players_loaded(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
	Store.set_game_players(JSON.parse(body.get_string_from_utf8()).result)
	get_node("CenterContainer/VBoxContainer/NbPlayers").set_text(str(Store._state.game.players.size()) + " joueurs")
