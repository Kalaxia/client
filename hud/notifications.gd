extends MarginContainer

const NOTIFICATION_SCENE = preload("res://hud/notification.tscn")


func _ready():
	Store.connect("notification_added", self, "_on_new_notification")


func _on_new_notification(notification):
	print(notification)
	var notif = NOTIFICATION_SCENE.instance()
	notif.notif = notification
	$List.add_child(notif)
	print(tr("notification.ok"))
