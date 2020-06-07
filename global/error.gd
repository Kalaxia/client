extends Node

func _ready():
	pass

func network_error(err):
	print("network error")
	print(str(err))

func network_response_error(err):
	match err:
		Network.FAIL_REASON.CANNOT_CONNECT_TO_HOST:
			Store.notify("Connexion impossible", "Le serveur de jeu n'est pas disponible.")
		Network.FAIL_REASON.CANNOT_RESOLVE_HOST:
			Store.notify("Connexion impossible", "Le nom de domaine du serveur est inconnu.'")
		var err:
			Store.notify("Erreur réseau", "Une erreur réseau est survenue.")
			printerr("Erreur reseau: " + str(err))
