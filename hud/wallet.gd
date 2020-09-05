extends HBoxContainer

var game_data = load(GameData.PATH_NAME)


func _ready():
	game_data.player.connect("wallet_updated", self, "_on_wallet_update")


func _on_wallet_update(amount):
	$Amount.text = amount as String
