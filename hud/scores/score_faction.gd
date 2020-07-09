extends Control

export(int) var faction = 0 setget set_faction

func _ready():
	$ProgressBar.connect("value_changed",self,"_on_progress_bar_changed")
	_update_faction()
	_update_scores(Store._state.scores)
	Store.connect("score_updated",self,"_on_score_updated")

func _on_score_updated(scores):
	_update_scores(scores)

func _update_scores(scores):
	for score in scores.values():
		if score.faction == faction:
			$ProgressBar.value = score.victory_points

func _on_progress_bar_changed(new_value):
	$ProgressBar/Label.text = "%3d / %3d" % [new_value , $ProgressBar.max_value]

func set_faction(f):
	faction = int(f)
	_update_faction()

func _update_faction():
	$TextureRect.texture = Utils.BANNERS[faction as int]
	var forground = $ProgressBar.get("custom_styles/fg")
	var faction_object = Store.get_faction(faction as float)
	forground.set_bg_color(Color(faction_object.color[0] / 255.0, faction_object.color[1] / 255.0, faction_object.color[2] / 255.0))
