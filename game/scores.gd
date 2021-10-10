extends Control

signal scene_requested(scene)

var _game_data = Store.game_data

const ASSETS = preload("res://resources/assets.tres")
const FACTION_SCORE_SCENE = preload("res://game/faction_score.tscn")

func _ready():
	get_node("Footer/BackToMenu").connect("pressed", self, "_back_to_menu")
	var scores = _game_data.scores
	var player_rankings = _game_data.player_rankings
	var nb_players = _game_data.players.size()
	if _game_data.player.faction.id == Store.victorious_faction:
		$Label.set_text(tr("game.score.victory"))
	else:
		$Label.set_text(tr("game.score.defeat"))
	for score in scores.values():
		var faction_score = FACTION_SCORE_SCENE.instance()
		faction_score.score = score
		$Factions.add_child(faction_score)
	
	var rankings = $PlayerRankingsContainer/Rankings
	
	for i in nb_players:
		for ranking in ["destroyed_ships", "lost_ships", "wealth", "successful_conquests", "lost_systems"]:
			display_score(rankings, player_rankings[ranking][i])


func display_score(table, player_ranking):
	var player = _game_data.get_player(player_ranking[0])
	
	var cell = PanelContainer.new()
	var container = VBoxContainer.new()
	var player_label = Label.new()
	player_label.set_align(Label.ALIGN_CENTER)
	player_label.set_text(player.username)
	player_label.add_color_override("font_color", player.faction.get_color())
	container.add_child(player_label)
	
	if player_ranking.size() > 2:
		container.add_child(get_ships_details(player_ranking[2]))
	else:
		var score = Label.new()
		score.set_align(Label.ALIGN_CENTER)
		score.set_text(String(player_ranking[1]))
		container.add_child(score)
	
	cell.add_child(container)
	table.add_child(cell)


func get_ships_details(ships):
	var grid = GridContainer.new()
	grid.set_columns(2)
	grid.set_h_size_flags(SIZE_EXPAND_FILL)
	grid.set_v_size_flags(SIZE_EXPAND_FILL)
	
	for model in ships:
		var cell = HBoxContainer.new()
		cell.set_h_size_flags(SIZE_EXPAND_FILL)
		
		var picto = TextureRect.new()
		picto.set_texture(ASSETS.get_resized_texture(ASSETS.ship_models[model].texture, 24, 24))
		
		var quantity = Label.new()
		quantity.set_text(String(ships[model]))
		
		cell.add_child(picto)
		cell.add_child(quantity)
		grid.add_child(cell)
		
	return grid


func _back_to_menu():
	_game_data.unload_data()
	emit_signal("scene_requested", "menu")
