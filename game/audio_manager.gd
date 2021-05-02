extends Node


func _ready():
	Audio.connect("building_finished_audio", self, "_on_building_finished_audio")
	Audio.connect("ship_queue_finished_audio", self, "_on_ship_queue_finished_audio")


func _on_building_finished_audio(building):
	play_system_sound(building.system)


func _on_ship_queue_finished_audio(ship_queue):
	play_system_sound(ship_queue.system)


func play_system_sound(system_id):
	var system = Store.game_data.get_system(system_id)
	if Store.game_data.does_belong_to_current_player(system):
		$AudioStackingShipQueueFinished.play_sound_positioned(system.coordinates * Utils.SCALE_SYSTEMS_COORDS)
