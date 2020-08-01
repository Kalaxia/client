extends HBoxContainer


func _ready():
	set_visible(false)
	Network.connect("GameStarted", self, "_on_game_started")
	Network.connect("Victory", self, "_on_victory")
	Store.connect("wallet_updated", self, "_on_wallet_update")


func _on_game_started(game):
	set_visible(true)


func _on_wallet_update(amount):
	$Amount.set_text(str(amount))


func _on_victory(data):
	set_visible(false)
