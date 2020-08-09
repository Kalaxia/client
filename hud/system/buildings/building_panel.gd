class_name BuildingPanel
extends SelectablePanelContainer

var building = null setget set_building

onready var texture_rect = $VBoxContainer/TextureRect
onready var label = $VBoxContainer/Label
onready var progress_bar = $VBoxContainer/ProgressBar


func _ready():
	# apparently there is no need to call 
	_update_elements()


func _process(delta):
	_update_process_bar()


func _update_elements():
	if texture_rect == null or label == null or progress_bar == null:
		return
	if building == null:
		texture_rect.texture = Utils.TEXTURE_BUILDING[""]
		label.text = tr("hud.details.buidlng.contruction")
		progress_bar.visible = false
	else:
		texture_rect.texture = Utils.TEXTURE_BUILDING[building.kind]
		label.text = tr("hud.details.buidlng." + building.kind)
		_update_process_bar()


func _update_process_bar():
	if progress_bar == null or building == null:
		return
	if building.status != "operational":
		set_process(true)
		progress_bar.visible = true
		var time_construction = max(building.built_at - building.created_at as float, 1.0)
		progress_bar.value = max(0.0, OS.get_system_time_msecs() - building.created_at as float) / time_construction
	else:
		set_process(false)
		progress_bar.visible = false


func set_building(new_building):
	building =  new_building
	_update_elements()
