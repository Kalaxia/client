extends Node


func _ready():
	Audio.connect("building_finished_audio", self, "_on_building_finished_audio")
	Audio.connect("ship_queue_finished_audio", self, "_on_ship_queue_finished_audio")


func _on_building_finished_audio(building):
	var system = Store.game_data.get_system(building.system)
	if Store.game_data.does_belong_to_current_player(system):
		$AudioStackingBuildingFinished.play_sound_positioned(system.coordinates * Utils.SCALE_SYSTEMS_COORDS)


func _on_ship_queue_finished_audio(ship_queue):
	var system = Store.game_data.get_system(ship_queue.system)
	if Store.game_data.does_belong_to_current_player(system):
		$AudioStackingShipQueueFinished.play_sound_positioned(system.coordinates * Utils.SCALE_SYSTEMS_COORDS)
