extends ShipModel
class_name KalaxiaShipModel

export(Texture) var texture

func _init(dict = null).(dict):
	pass


func load_dict(dict):
	if dict == null:
		return
	.load_dict(dict)
	texture = load("res://resources/assets/2d/picto/ships/%s.svg" % category )
