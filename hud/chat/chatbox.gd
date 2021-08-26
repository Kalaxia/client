extends Control

onready var messages_list = $MessagesContainer/MessagesList
onready var message_editor = $MessageEditor
onready var scrollbar = $MessagesContainer.get_v_scrollbar()

func _ready():
	message_editor.connect("text_entered", self, "_on_text_entered")
	Network.connect("NewChatMessage", self, "_on_message_received")


func _on_text_entered(message):
	if message == '':
		message_editor.release_focus()
		return
	
	Network.req(self, "_on_message_sent",
		"/api/games/" + Store.game_data.id + "/communications/send/",
		HTTPClient.METHOD_POST,
		[ "Content-Type: application/json" ],
		JSON.print({ "content" : message })
	)


func _on_message_sent(err, response_code, _headers, body):
	if err:
		ErrorHandler.network_response_error(err)
		return


func _on_message_received(data):
	var player = Store.game_data.get_player(data.author)
	var player_color = player.faction.get_color()
	
	var new_line = HBoxContainer.new()
	var username = Label.new()
	username.set("custom_colors/font_color", player_color)
	username.text = "[" + player.username + "] : "
	var content = Label.new()
	content.text = data.content
	new_line.add_child(username)
	new_line.add_child(content)
	
	messages_list.add_child(new_line)
	if 20 <= messages_list.get_child_count():
		var older_message = messages_list.get_child(0)
		messages_list.remove_child(older_message)
		older_message.queue_free()
		
	message_editor.clear()
	message_editor.release_focus()
	
	$MessagesContainer.scroll_vertical = scrollbar.max_value


func _input(ev):
	if not ev is InputEventKey or ev.echo or not ev.pressed:
		return
	if ev.scancode == KEY_ENTER and not message_editor.has_focus():
		message_editor.call_deferred('grab_focus')
	if ev.scancode == KEY_ESCAPE and message_editor.has_focus():
		message_editor.clear()
		message_editor.release_focus()
