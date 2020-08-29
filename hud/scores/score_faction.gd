extends Control

export(int) var faction = 0 setget set_faction

onready var progress_bar = $ProgressBar
onready var texture = $TextureRect

const assets = load("res://resources/assets.tres")

func _ready():
	progress_bar.max_value = constants.victory_points
	progress_bar.connect("value_changed",self,"_on_progress_bar_changed")
	Network.connect("FactionPointsUpdated", self, "_on_score_updated")
	_update_faction()
	_update_scores(Store._state.scores)


func set_faction(f):
	if f <= 0:
		return
	faction = int(f)
	_update_faction()


func _on_score_updated(scores):
	_update_scores(scores)


func _update_scores(scores):
	for score in scores.values():
		if score.faction == faction:
			progress_bar.value = score.victory_points


func _on_progress_bar_changed(new_value):
	progress_bar.get_node("Label").text = "%3d / %3d" % [new_value , progress_bar.max_value]


func _update_faction():
	if texture == null:
		return
	texture.texture = assets.factions[faction as int].banner
	var forground = progress_bar.get("custom_styles/fg").duplicate()
	var faction_object = assets.factions[faction as int]
	forground.set_bg_color(faction_object.display_color)
	progress_bar.set("custom_styles/fg", forground)
