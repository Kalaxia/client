extends Node

func _ready():
	pass

func network_error(err):
	print(tr("error.network_error"))
	print(str(err))

func network_response_error(err):
	match err:
		ERR_CANT_CONNECT:
			Store.notify(tr("error.connexion_impossible"), tr("error.server_not_avaliable"))
		ERR_CANT_RESOLVE:
			Store.notify(tr("error.connexion_impossible"), tr("error.unkown_domain_name"))
		ERR_INVALID_PARAMETER:
			Store.notify(tr("error.http_not_connected"), tr("error.server_not_avaliable"))
		var err:
			Store.notify(tr("error.network_error"), tr("error.network_error_content"))
			printerr(tr("error.network_error") + ":" + err as String)
