extends MenuContainer


func _exit_tree():
	# save config only when the menu existe the tree in order to not write too much on disck
	Config.save_config_file()
