extends Control

var _time = 0.0
const TIME_LOADING = 5.0
const COLOR_ATTENUATION = 3.0

signal scene_requested(scene)

func _ready():
	Network.connect("GameStarted", self, "_on_game_started")
	Network.connect("SystemsCreated", self, "_on_systems_created")
	Network.req(self, "_on_players_loaded", "/api/games/" + Store._state.game.id + "/players/")
	var forground = get_node("CenterContainer/VBoxContainer/ProgressBar").get("custom_styles/fg")
	var faction = Store.get_faction(float(Store._state.player.faction))
	# if this does not work you may have a type problem for the keys of the Store._state.faction 
	forground.set_bg_color(Color(faction.color[0]/255.0 / COLOR_ATTENUATION,faction.color[1]/255 /COLOR_ATTENUATION,faction.color[2]/255.0 / COLOR_ATTENUATION))

func _process(delta):
	_time += delta
	get_node("CenterContainer/VBoxContainer/ProgressBar").set_value(min(_time/TIME_LOADING*100.0,99.99))

func init_systems(systems):
	for s in systems:
		s.fleets = {}
		Store._state.game.systems[s.id] = s

func _on_systems_created(data):
	Store._state.game.systems = {}
	Network.req(self, "_on_systems_loaded", "/api/games/" + Store._state.game.id + "/systems/?page=1&limit=100")
	
func _on_systems_loaded(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
	var pagination = Network.extract_pagination_data(headers["content-range"])
	if pagination["count"] > pagination["page"] * pagination["limit"]:
		Network.req(
			self,
			"_on_systems_loaded",
			"/api/games/" + Store._state.game.id +
			"/systems/?page=" + str(pagination["page"] + 1) +
			"&limit=" + str(pagination["limit"]))
	init_systems(JSON.parse(body.get_string_from_utf8()).result)

func _on_game_started(data):
	Store._state.player.wallet = 0
	emit_signal("scene_requested", "game")

func _on_players_loaded(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
	Store.set_game_players(JSON.parse(body.get_string_from_utf8()).result)
	get_node("CenterContainer/VBoxContainer/NbPlayers").set_text(tr("menu.loading.number_player") % Store._state.game.players.size())
