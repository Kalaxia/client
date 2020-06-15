extends Node

func _ready():
	pass

func network_error(err):
	print("network error")
	print(str(err))

func network_response_error(err):
	match err:
		ERR_CANT_CONNECT:
			Store.notify("Connexion impossible", "Le serveur de jeu n'est pas disponible.")
		ERR_CANT_RESOLVE:
			Store.notify("Connexion impossible", "Le nom de domaine du serveur est inconnu.'")
		ERR_INVALID_PARAMETER:
			Store.notify("Client HTTP non connecté", "Le serveur de jeu n'est pas disponible.'")
		var err:
			Store.notify("Erreur réseau", "Une erreur réseau est survenue.")
			printerr("Erreur reseau: " + err)
