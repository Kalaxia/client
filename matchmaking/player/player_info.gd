extends PanelContainer

signal player_updated(player)

var player = null
var new_username = ""
var _is_locked_username_change = Utils.Lock.new()

onready var username_input = $Container/UsernameInput
onready var ready_input = $Container/ReadyInput
onready var faction_choice = $Container/FactionChoice
onready var user_name_input = $Container/UsernameInput
onready var timer_update_username = $Container/UsernameInput/UpdateNameTimer
onready var background = $Background


func _ready():
	ready_input.pressed = player.ready
	init_faction_choices()
	user_name_input.placeholder_text = tr("menu.player_info.input_text_placeholder")
	if player.id == Store._state.player.id:
		new_username = player.username
		background.color = Color(0,0,0)
		username_input.editable = true
		username_input.connect("text_changed", self, "_on_text_changed")
		username_input.connect("text_entered", self, "_on_text_entered")
		ready_input.connect("pressed", self, "toggle_ready")
		timer_update_username.connect("timeout",self,"_on_timer_timeout")
		if player.username != "" || (player.faction != null && player.faction != 0.0 ):
			send_update()
	username_input.set_text(get_username())


func _on_text_entered(input_text):
	new_username = input_text
	timer_update_username.stop()
	update_username(input_text)


func _on_text_changed(input_text):
	new_username = input_text
	# this reset the timer at the wait_time if the timer was runing
	timer_update_username.start()


func _on_timer_timeout():
	update_username(new_username)


func init_faction_choices():
	faction_choice.add_item(tr("menu.player_info.faction_drop_down_0"), 0)
	faction_choice.set_item_disabled(0, true)
	for faction in Store._state.factions.values():
		var image = Utils.BANNERS_SMALL[faction.id as int]
		var texture = ImageTexture.new()
		texture.create_from_image(image, ImageTexture.FLAG_MIPMAPS | ImageTexture.FLAG_FILTER | ImageTexture.FLAG_ANISOTROPIC_FILTER)
		texture.set_size_override(Vector2(50, 50))
		# not keys for faction
		faction_choice.add_icon_item(texture, tr(faction.name), faction.id)
	if player.id == Store._state.player.id:
		faction_choice.disabled = false
		faction_choice.flat = false
		faction_choice.connect("item_selected", self, "update_faction")
	faction_choice.selected = player.faction if player.faction != null else 0


func get_username():
	if player.id == Store._state.player.id:
		return new_username
	else:
		return tr("general.unkown_username") if (player.username == "") else player.username


func update_data(data):
	player = data
	var caret_position = user_name_input.caret_position
	user_name_input.set_text(get_username())
	user_name_input.caret_position = caret_position
	faction_choice.selected = faction_choice.get_item_index(player.faction) if player.faction != null else 0
	ready_input.pressed = player.ready


func update_username(username):
	if _is_locked_username_change.try_lock() != Utils.Lock.LOCK_STATE.OK:
		new_username = username
		timer_update_username.start() 
		# if we can not lock we start the timer and try later
		return
	Store._state.player.username = username
	send_update()


func update_faction(index):
	Store._state.player.faction = faction_choice.get_item_id(index)
	send_update()


func toggle_ready():
	Store._state.player.ready = not player.ready
	send_update()


func send_update():
	_check_ready_state()
	Network.req(self, "_on_request_completed"
		, "/api/players/me/"
		, HTTPClient.METHOD_PATCH
		, [ "Content-Type: application/json" ]
		, JSON.print({
			"username": Store._state.player.username,
			"faction_id": Store._state.player.faction,
			"is_ready": Store._state.player.ready
		})
	)


func _on_request_completed(err, response_code, headers, body):
	_is_locked_username_change.unlock()
	if response_code != HTTPClient.RESPONSE_NO_CONTENT:
		Store.notify(
			tr("matchmaking.error.username_already_taken.title"),
			tr("matchmaking.error.username_already_taken.content")
		)
		return
	emit_signal("player_updated", Store._state.player)


func _check_ready_state():
	if player.id != Store._state.player.id:
		return
	# we want to do thar only if this is the current player
	var is_info_missing = Store._state.player.faction == null or Store._state.player.username == ""
	var input = ready_input
	input.disabled = is_info_missing
	if is_info_missing:
		Store._state.player.ready = false
		input.pressed = false
