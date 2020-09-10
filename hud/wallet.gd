extends HBoxContainer

var game_data = Store.game_data


func _ready():
	game_data.player.connect("wallet_updated", self, "_on_wallet_update")


func _on_wallet_update(amount):
	$Amount.text = amount as String
