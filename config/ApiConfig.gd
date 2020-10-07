extends Resource
class_name ApiConfig

export var dns : String = "127.0.0.1"
export(int, 0, 65535) var port = 8080
export var scheme : String = "http"
export var ws_scheme : String = "ws"
