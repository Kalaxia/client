class_name VolumeOption
extends PanelContainer

export(int) var bus_id = 0 setget set_bus_id
export(bool) var disabled = false setget set_disabled

onready var volume_slider = $HBoxContainer/VolumeSlider
onready var bus_name_label = $HBoxContainer/BusName
onready var volume_label = $HBoxContainer/volume


func _ready():
	volume_slider.connect("value_changed", self, "_on_value_changed")
	_refersh_data()
	_update_disabled_state()


func _refersh_data():
	if bus_name_label == null or volume_slider == null:
		return
	bus_name_label.text = tr("audio.bus." + AudioServer.get_bus_name(bus_id))
	var value_volume = db2linear(AudioServer.get_bus_volume_db(bus_id))
	volume_slider.value = value_volume
	set_volume_lable(value_volume)


func set_volume_lable(value_volume):
	volume_label.text = tr("menu.option.audio.volume_label %d %f") % [floor(value_volume * 100), linear2db(value_volume)]  


func _on_value_changed(value_slider):
	var value_volume = value_slider if value_slider != 0 else db2linear(Utils.AUDIO_VOLUME_DB_MIN)
	AudioServer.set_bus_volume_db(bus_id, linear2db(value_volume))
	set_volume_lable(value_volume)
	Config.set_audio_volume(AudioServer.get_bus_name(bus_id), value_slider)


func set_bus_id(new_id : int):
	if new_id <= 0:
		return
	var name = AudioServer.get_bus_name(new_id)
	if name == "" || name == null:
		return
	bus_id = new_id
	_refersh_data()


func set_disabled(is_disabled : bool):
	disabled = is_disabled
	_update_disabled_state()

func _update_disabled_state():
	if volume_slider:
		volume_slider.editable = not disabled
