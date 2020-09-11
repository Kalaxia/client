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
}

var _is_in_game = false setget _set_is_in_game


func _ready():
	Config.connect("locale_reloaded", self, "_on_locale_reloaded")
	if scenes["menu"].scene == null or Network.token == null:
		change_scene_loading(scenes)
		yield($Level.get_child(0), "finished")
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
