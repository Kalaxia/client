extends HBoxContainer


func _ready():
	Store.connect("wallet_updated", self, "_on_wallet_update")


func _on_wallet_update(amount):
	$Amount.set_text(str(amount))
