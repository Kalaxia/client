extends Node

func _ready():
	pass

func network_error(err):
	print("network error")
	print(str(err))

func network_response_error(err):
	if err == HTTPRequest.RESULT_CANT_CONNECT:
		Store.notify("Connexion impossible", "Le serveur de jeu n'est pas disponible.")
	elif err == HTTPRequest.RESULT_TIMEOUT:
		Store.notify("Connexion échouée", "Le jeu ne peut se connecter au serveur. Contacter l'administrateur.")
	else:
		Store.notify("Erreur réseau", "Une erreur réseau est survenue.")
		print(str(err))
