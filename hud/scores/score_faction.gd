extends Control

export(int) var faction = 0 setget set_faction

onready var progress_bar = $ProgressBar
onready var texture = $TextureRect


func _ready():
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
	texture.texture = Utils.BANNERS[faction as int]
	var forground = progress_bar.get("custom_styles/fg").duplicate()
	var faction_object = Store.get_faction(faction as float)
	forground.set_bg_color(Color(faction_object.color[0] / 255.0, faction_object.color[1] / 255.0, faction_object.color[2] / 255.0))
	progress_bar.set("custom_styles/fg", forground)
