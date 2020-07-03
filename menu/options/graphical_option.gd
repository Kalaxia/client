extends VBoxContainer

var is_resizable = false
const FORCE_DISABLED_RESIZABLE_ON_EXIT = true

func _ready():
	$fullscreen.connect("option_pressed",self,"_on_fullscreen_pressed")
	$Maximize.connect("option_pressed",self,"_on_maximize_pressed")
	$Redimentioner.connect("option_pressed",self,"_on_resize_pressed")
	$screen.connect("option_changed",self,"_on_screen_changed")
	get_tree().get_root().connect("size_changed", self, "_on_resize_window")
	_check_option_state()
	
func _check_option_state():
	$fullscreen.is_checked = OS.window_fullscreen
	$Maximize.is_checked = OS.window_maximized
	$Redimentioner.is_checked = OS.window_resizable
	$Maximize.disabled = OS.window_fullscreen
	$Redimentioner.disabled =  OS.window_maximized || OS.window_fullscreen
	$screen.disabled = OS.get_screen_count() <= 1
	$screen.max_value = OS.get_screen_count()-1
	$screen.value = OS.current_screen
	
func _on_resize_window():
	if is_resizable:
		Config.set_config_window_resolution(OS.window_size)
	_check_option_state()

func _on_fullscreen_pressed(is_fullscreen):
	if is_fullscreen:
		is_resizable = false
		Utils.set_window_resizable(false)
		Config.set_config_window_maximized(false)
	OS.window_fullscreen = is_fullscreen
	Config.set_config_window_fullscreen(is_fullscreen)
	if ! is_fullscreen:
		OS.set_window_size(Config.get_window_resolution_from_config())
	_check_option_state()

func _on_maximize_pressed(is_maximize):
	if is_maximize:
		is_resizable = false
		Utils.set_window_resizable(false)
	Config.set_config_window_maximized(is_maximize)
	OS.set_window_maximized(is_maximize)
	_check_option_state()

func _on_resize_pressed(bool_resize):
	is_resizable = bool_resize
	Utils.set_window_resizable(bool_resize)

func _on_screen_changed(screen_id):
	Config.set_config_window_screen(screen_id)
	if OS.current_screen == screen_id:
		return
	if OS.window_fullscreen:
		OS.window_fullscreen = false
		OS.set_current_screen (screen_id)
		OS.window_fullscreen = true
	else:
		OS.set_current_screen (screen_id)

func _exit_tree():
	if FORCE_DISABLED_RESIZABLE_ON_EXIT:
		# we impose that when we get back the window is not resizable
		Utils.set_window_resizable(false)
