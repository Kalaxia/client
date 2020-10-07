extends Control

signal scene_requested(scene)

const TIME_LOADING = 5.0
const COLOR_DARKENING = 0.7
const ASSETS = preload("res://resources/assets.tres")

var _time = 0.0

onready var progress_bar = $CenterContainer/VBoxContainer/ProgressBar
onready var nb_players_label = $CenterContainer/VBoxContainer/NbPlayers


func _ready():
	Network.connect("GameStarted", self, "_on_game_started")
	Network.connect("SystemsCreated", self, "_on_systems_created")
	Network.req(self, "_on_players_loaded", "/api/games/" + Store._state.game.id + "/players/")
	var forground = progress_bar.get("custom_styles/fg")
	var faction = ASSETS.factions[Store._state.player.faction]
	# if this does not work you may have a type problem for the keys of the Store._state.faction
	forground.set_bg_color(faction.display_color.darkened(COLOR_DARKENING))


func _process(delta):
	# todo change to load base and not time base
	_time += delta
	progress_bar.set_value(min(_time / TIME_LOADING * 100.0, 99.99))


func init_systems(systems):
	for s in systems:
		if s.player != null and s.player == Store._state.player.id:
			Store.request_hangar(s)
		if s.player != null and Store._state.game.players[s.player].faction == Store._state.player.faction:
			Store.request_buildings(s)
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
	nb_players_label.set_text(tr("menu.loading.number_player %d") % Store._state.game.players.size())
