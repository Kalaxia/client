extends Control

const ASSETS = preload("res://resources/assets.tres")

export(int) var faction = 0 setget set_faction

var game_data : GameData = load(GameData.PATH_NAME)

onready var progress_bar = $ProgressBar
onready var texture = $TextureRect


func _ready():
	progress_bar.connect("value_changed",self,"_on_progress_bar_changed")
	game_data.connect("score_updated", self, "_on_score_updated")
	progress_bar.max_value = ASSETS.constants.victory_points
	# we have to update one to shows the correct numbers of max points
	# value_changed is not triggered if we set the same value as before
	_on_progress_bar_changed(0)
	_update_faction()
	_update_scores(game_data.scores)


func set_faction(f):
	if f <= 0:
		return
	faction = int(f)
	_update_faction()


func _on_score_updated():
	_update_scores(game_data.scores)


func _update_scores(scores): # scores : dict with int as key and ScoreFaction as values
	if scores.has(faction):
		_update_score_display(scores[faction])


func _update_score_display(score_faction):
	progress_bar.value = score_faction.victory_points


func _on_progress_bar_changed(new_value):
	progress_bar.get_node("Label").text = "%3d / %3d" % [new_value , progress_bar.max_value]


func _update_faction():
	if texture == null:
		return
	var faction_object = ASSETS.factions[faction]
	texture.texture = faction_object.banner
	var forground = progress_bar.get("custom_styles/fg").duplicate()
	forground.set_bg_color(faction_object.display_color)
	progress_bar.set("custom_styles/fg", forground)
