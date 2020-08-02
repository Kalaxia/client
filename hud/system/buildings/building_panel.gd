extends SelectablePanelContainer

export(String) var building_type = "" setget set_building_type

var build_queue = null setget set_build_queue

onready var texture_rect = $VBoxContainer/TextureRect
onready var label = $VBoxContainer/Label
onready var progress_bar = $VBoxContainer/ProgressBar

func _ready():
	._ready()
	_update_elements()


func set_building_type(new_type):
	if new_type != ""  and not Utils.BUILDING_LIST.has(new_type):
		return
	building_type = new_type
	_update_elements()


func _update_elements():
	if build_queue == null:
		texture_rect.texture = Utils.TEXTURE_BUILDING[building_type]
		label.text = tr("hud.details.buidlng." + building_type) if building_type != "" else tr("hud.details.buidlng.contruction")
		progress_bar.visible = false
	else:
		texture_rect.texture = Utils.TEXTURE_BUILDING[build_queue.building]
		label.text = tr("hud.details.buidlng." + build_queue.building)
		progress_bar.visible = true
		var time_construction = max(build_queue.finished_at - build_queue.started_at as float, 1.0)
		progress_bar.value = max(0.0, OS.get_system_time_msecs() - build_queue.started_at as float) / time_construction
		


func set_build_queue(queue):
	build_queue =  queue
	set_building_type(build_queue.building_type)
