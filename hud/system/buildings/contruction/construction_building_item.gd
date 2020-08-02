class_name ConstructionBuildingItem
extends MarginContainer

signal building_contructing(building_queue)

export(String) var building_type = "" setget set_building_type

var _lock_request_build = Utils.Lock.new() setget private_set, private_get

onready var texture_rect = $PanelContainer/HBoxContainer/TextureRect
onready var label = $PanelContainer/HBoxContainer/Label
onready var button = $PanelContainer/HBoxContainer/Button


func _ready():
	_updates_elements()
	button.connect("pressed", self, "_on_build_button")


func set_building_type(new_type):
	if not Utils.BUILDING_LIST.has(new_type):
		return
	building_type = new_type
	_updates_elements()


func private_set(variant):
	pass


func private_get():
	pass


func _updates_elements():
	if texture_rect == null:
		return
	texture_rect.texture = Utils.TEXTURE_BUILDING[building_type]
	label.text = tr("hud.details.buidlng." + building_type) if building_type != "" else tr("hud.details.buidlng.contruction")


func _on_build_button():
	if not _lock_request_build.try_lock():
		return
	Network.req(self, "_on_building_construction_started",
			"/api/games/" + Store._state.game.id +
			"/systems/" + Store._state.selected_system.id +
			"/buildings/",
			HTTPClient.METHOD_POST,
			[ "Content-Type: application/json" ],
			JSON.print({"kind" : building_type})
	)


func _on_building_construction_started(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
	if response_code == HTTPClient.RESPONSE_CREATED:
		var building_queue = JSON.parse(body.get_string_from_utf8()).result
		emit_signal("building_contructing", building_queue)
	_lock_request_build.unlock()
