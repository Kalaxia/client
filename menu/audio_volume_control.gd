extends PanelContainer


export(int) var bus_id = 0 setget set_bus_id

# Called when the node enters the scene tree for the first time.
func _ready():
	$HBoxContainer/VolumeSlider.connect("value_changed",self,"_on_value_changed")
	_refersh_data()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _refersh_data():
	$HBoxContainer/BusName.text = AudioServer.get_bus_name(bus_id)
	var value_volume = db2linear(AudioServer.get_bus_volume_db(bus_id))
	$HBoxContainer/VolumeSlider.value = value_volume
	set_volume_lable(value_volume)

func set_volume_lable(value_volume):
	$HBoxContainer/volume.text = "%3.3d %s (%7.2f dB)" % [floor(value_volume * 100),"%",linear2db(value_volume)]  

func _on_value_changed(value_slider):
	var value_volume = value_slider if value_slider != 0 else db2linear(-100)
	AudioServer.set_bus_volume_db(bus_id,linear2db(value_volume))
	set_volume_lable(value_volume)
	
func set_bus_id(new_id : int):
	if new_id <= 0:
		return
	var name = AudioServer.get_bus_name(new_id)
	if name == "" || name == null:
		return
	bus_id = new_id
	$HBoxContainer/BusName.text = name
	$HBoxContainer/VolumeSlider.value = db2linear(AudioServer.get_bus_volume_db(bus_id))
