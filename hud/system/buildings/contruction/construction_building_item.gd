class_name ConstructionBuildingItem
extends MarginContainer

signal building_constructing(building)

const ASSETS = preload("res://resources/assets.tres")

export(Resource) var building_type = null setget set_building_type # resource

var _game_data : GameData = Store.game_data
var _lock_request_build = Utils.Lock.new() setget private_set, private_get

onready var texture_rect = $PanelContainer/HBoxContainer/TextureRect
onready var label = $PanelContainer/HBoxContainer/Label
onready var button = $PanelContainer/HBoxContainer/Button
onready var label_cost = $PanelContainer/HBoxContainer/LabelCost
onready var label_time = $PanelContainer/HBoxContainer/LabelTime


func _ready():
	button.connect("pressed", self, "_on_build_button")
	_game_data.player.connect("wallet_updated", self, "_on_wallet_updated")
	_lock_request_build.connect("changed_state", self, "_on_lock_changed_state")
	_update_build_button_state()
	_updates_elements()


func set_building_type(new_type):
	building_type = new_type
	_updates_elements()


func private_set(_variant):
	pass


func private_get():
	return null


func _on_wallet_updated(_amount):
	_update_build_button_state()


func _update_build_button_state():
	button.disabled = _game_data.player.wallet < building_type.cost or _lock_request_build.get_is_locked()


func _on_lock_changed_state(_state_is_locked):
	_update_build_button_state()


func _updates_elements():
	if texture_rect == null:
		return
	texture_rect.texture = building_type.texture
	label.text = tr("hud.details.buidlng." + building_type.kind) if building_type != null else tr("hud.details.buidlng.contruction")
	label_cost.text = tr("hud.details.buidlng.cost %d") % building_type.cost
	label_time.text = tr("hud.details.buidlng.time %d") % building_type.construction_time


func _on_build_button():
	if not _lock_request_build.try_lock():
		return
	if _game_data.player.wallet < building_type.cost:
		_lock_request_build.unlock()
		Store.notify(tr("notification.error.not_enought_cred.title"), tr("notification.error.not_enought_cred.content"))
		return
	Network.req(self, "_on_building_construction_started",
			"/api/games/" + _game_data.id +
			"/systems/" + _game_data.selected_state.selected_system.id +
			"/buildings/",
			HTTPClient.METHOD_POST,
			[ "Content-Type: application/json" ],
			JSON.print({"kind" : building_type.kind}),
			[_game_data.selected_state.selected_system]
	)


func _on_building_construction_started(err, response_code, _headers, body, system):
	if err:
		ErrorHandler.network_response_error(err)
	if response_code == HTTPClient.RESPONSE_CREATED:
		var building = Building.new(JSON.parse(body.get_string_from_utf8()).result)
		system.add_building_to_system(building)
		_game_data.player.update_wallet(- building_type.cost)
		emit_signal("building_constructing", building)
	_lock_request_build.unlock()
