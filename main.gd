extends Node2D

var loading_scene = preload("res://global/loading_screen.tscn")
var menu_scene = preload("res://menu/menu_screen.tscn")
var lobby_scene = preload("res://matchmaking/lobby/lobby.tscn")
var game_loading_scene = preload("res://matchmaking/game/game_loading.tscn")
var game_scene = preload("res://game/game.tscn")
var scores_scene = preload("res://game/scores.tscn")
var option_menu = preload("res://menu/menu_option.tscn")
var credits_menu = preload("res://menu/menu_credits.tscn")
var scores_hud = preload("res://hud/scores/scores.tscn")

var _is_in_game = false setget _set_is_in_game

func _ready():
	Config.connect("reload_locale",self,"_on_reload_locale")
	$ParallaxBackground/HUD/HudMenu.connect("back_main_menu", self, "_on_back_to_main_menu")
	change_level(loading_scene) if Network.token == null else change_level(menu_scene)
	$ParallaxBackground/HUD/ScoresContainer.visible = false

func change_level(level_scene):
	for l in $Level.get_children(): l.queue_free()
	var level = level_scene.instance()
	level.connect("scene_requested", self, "_on_scene_request")
	$Level.add_child(level)

func _on_back_to_main_menu():
	Network.req(self, "_on_player_left_game", "/api/games/" + Store._state.game.id + "/players/", HTTPClient.METHOD_DELETE)
	
func _on_player_left_game(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
	$ParallaxBackground/HUD/Wallet.visible = false
	$ParallaxBackground/HUD/SystemDetails.visible = false
	change_level(menu_scene)

func _on_scene_request(scene):
	_set_is_in_game(false)
	if scene == 'lobby':
		change_level(lobby_scene)
	elif scene == 'menu':
		change_level(menu_scene)
	elif scene == 'option_menu':
		change_level(option_menu)
	elif scene == 'credits_menu':
		change_level(credits_menu)
	elif scene == 'game_loading':
		change_level(game_loading_scene)
	elif scene == 'game':
		_set_is_in_game(true)
		change_level(game_scene)
	elif scene == "scores":
		change_level(scores_scene)
	else:
		printerr(tr("Unknown requested scene : ") + scene)

func _on_reload_locale():
	get_tree().reload_current_scene()

func _set_is_in_game(is_in_game_new):
	if is_in_game_new == _is_in_game:
		return
	_is_in_game = is_in_game_new
	if not is_in_game_new:
		$ParallaxBackground/HUD/ScoresContainer.visible = false
		for i in $ParallaxBackground/HUD/ScoresContainer.get_children():
			i.queue_free()
	else:
		$ParallaxBackground/HUD/ScoresContainer.add_child(scores_hud.instance())


func _unhandled_input(event):
	if event.is_action_pressed("ui_hud_scores"):
		if _is_in_game :
			$ParallaxBackground/HUD/ScoresContainer.visible = true
	elif event.is_action_released("ui_hud_scores"):
		$ParallaxBackground/HUD/ScoresContainer.visible = false
