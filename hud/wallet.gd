extends HBoxContainer

var _game_data = Store.game_data


func _ready():
	_game_data.player.connect("wallet_updated", self, "_on_wallet_update")


func _on_wallet_update(amount):
	$Amount.text = amount as String
