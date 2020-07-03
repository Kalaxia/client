extends HBoxContainer

onready var factions_column = [$FactionColumn0,$FactionColumn1,$FactionColumn2,$FactionColumn3]

func add_player(player):
	for i in factions_column:
		if ((player.faction == null || player.faction as int== 0) and i.faction == 0) or player.faction as int == i.faction:
			i.add_player(player)
			return
	factions_column[0].add_player(player)

func update_player(player):
	for i in factions_column:
		i.update_player(player)

func remove_player(player):
	for i in factions_column:
		i.remove_player(player)
