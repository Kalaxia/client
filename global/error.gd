extends Node
class_name ErrorHandler


static func network_error(err):
	print(translate("error.network_error"))
	print(str(err))


static func network_response_error(err):
	match err:
		ERR_CANT_CONNECT:
			Store.notify(translate("error.connexion_impossible"), translate("error.server_not_avaliable"))
		ERR_CANT_RESOLVE:
			Store.notify(translate("error.connexion_impossible"), translate("error.unkown_domain_name"))
		ERR_INVALID_PARAMETER:
			Store.notify(translate("error.http_not_connected"), translate("error.server_not_avaliable"))
		var err:
			Store.notify(translate("error.network_error"), translate("error.network_error_content"))
			printerr(translate("error.network_error") + ":" + err as String)


static func translate(string : String) -> String:
	return TranslationServer.translate(string)
