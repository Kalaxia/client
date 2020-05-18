extends HBoxContainer

func _ready():
	set_visible(false)
	Network.connect("GameStarted", self, "_on_game_started")
	Network.connect("PlayerIncome", self, "_on_player_income")
	
func _on_game_started(game):
	set_visible(true)
	
func _on_player_income(data):
	Store._state.player.wallet += data.income
	$Amount.set_text(str(Store._state.player.wallet))
