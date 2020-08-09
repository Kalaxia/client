extends Node

var scenes = {
	"loading" : {
		"path" : "res://global/loading_screen.tscn",
		"scene" : preload("res://global/loading_screen.tscn"),
	},
	"menu" : {
		"path" : "res://menu/menu_screen.tscn",
		"scene" : null,
	},
	"lobby" : {
		"path" : "res://matchmaking/lobby/lobby.tscn",
		"scene" : null,
	},
	"game_loading" : {
		"path" : "res://matchmaking/game/game_loading.tscn",
		"scene" : null,
	},
	"game" : {
		"path" : "res://game/game.tscn",
		"scene" : null,
	},
	"scores" : {
		"path" : "res://game/scores.tscn",
		"scene" : null,
	},
	"option_menu" : {
		"path" : "res://menu/menu_option.tscn",
		"scene" : null,
	},
	"credits_menu" : {
		"path" : "res://menu/menu_credits.tscn",
		"scene" : null,
	},
	"scores_hud" : {
		"path" : "res://hud/scores/scores.tscn",
		"scene" : null,
	},
	"hud" :{
		"path" : "res://hud/hud.tscn",
		"scene" : null,
	}
}

var _is_in_game = false setget _set_is_in_game


func _ready():
	Config.connect("locale_reloaded", self, "_on_locale_reloaded")
	if scenes["menu"].scene == null or Network.token == null:
		change_scene_loading(scenes)
		yield($Level.get_child(0), "finished")
	$ParallaxBackground.add_child(scenes.hud.scene.instance())
	$ParallaxBackground/HUD/HudMenu.connect("back_main_menu", self, "_on_back_to_main_menu")
	$ParallaxBackground/HUD/ScoresContainer.visible = false
	change_level(scenes.menu.scene)


func change_scene_loading(load_queue_param):
	change_level(scenes.loading.scene)
	var loading_node = $Level.get_child(0)
	loading_node.load_queue = load_queue_param
	if not loading_node.is_connected("ressource_loaded", self, "_on_ressource_loaded"):
		loading_node.connect("ressource_loaded", self, "_on_ressource_loaded")
	if not loading_node.is_connected("finished", self, "_on_load_finished"):
		loading_node.connect("finished", self, "_on_load_finished")


func _on_ressource_loaded(ressource_name, ressource):
	scenes[ressource_name].scene = ressource


func _on_load_finished():
	pass


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
	$ParallaxBackground/HUD/SystemDetails.visible = false
	change_level(scenes.menu.scene)


func _on_scene_request(scene):
	print(scene)
	_set_is_in_game(scene == "game")
	if scenes.has(scene):
		if scenes[scene].scene == null:
			var scene_to_load = {}
			scene_to_load[scene] = scenes[scene]
			change_scene_loading(scene_to_load)
			yield($Level.get_child(0), "finished")
		change_level(scenes[scene].scene)
	else:
		printerr(tr("Unknown requested scene : ") + scene)


func _on_locale_reloaded():
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
		$ParallaxBackground/HUD/ScoresContainer.add_child(scenes.scores_hud.scene.instance())


func _unhandled_input(event):
	if _is_in_game :
		if event.is_action_pressed("ui_hud_scores"):
			$ParallaxBackground/HUD/ScoresContainer.visible = true
		elif event.is_action_released("ui_hud_scores"):
			$ParallaxBackground/HUD/ScoresContainer.visible = false
