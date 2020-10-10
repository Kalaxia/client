tool
class_name EnvironmentConfig
extends Resource

export(String) var api_dns = "127.0.0.1"
export(int, 0, 65535) var api_port = 8080
export(String, "http", "https") var api_scheme = "http"
export(String, "ws", "wss") var ws_scheme = "ws"

export(bool) var debug_activated = false
export(bool) var debug_auto_fill_lobby = false
