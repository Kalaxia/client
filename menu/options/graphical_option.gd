extends VBoxContainer



func _ready():
	$borderless.connect("option_pressed",self,"_on_borderless_pressed")
	$Maximize.connect("option_pressed",self,"_on_maximize_pressed")
	$Redimentioner.connect("option_pressed",self,"_on_resize_pressed")
	$screen.connect("option_changed",self,"_on_screen_changed")
	get_tree().get_root().connect("size_changed", self, "_on_resize_window")
	_check_option_state()
	
func _check_option_state():
	$borderless.is_checked = OS.window_borderless
	$Maximize.is_checked = OS.window_maximized
	$Redimentioner.is_checked = OS.window_resizable
	$Maximize.disabled = OS.window_borderless
	$Redimentioner.disabled =  OS.window_maximized || OS.window_borderless
	$screen.disabled = OS.get_screen_count() <= 1
	$screen.max_value = OS.get_screen_count()-1
	$screen.value = OS.current_screen
	
func _on_resize_window():
	_check_option_state()

func _on_borderless_pressed(is_borderless):
	if is_borderless:
		Utils.set_windows_resizable(false)
	OS.set_borderless_window(is_borderless)
	OS.set_window_maximized(is_borderless)
	if ! is_borderless:
		OS.set_window_size(Vector2(1280,720))
	_check_option_state()

func _on_maximize_pressed(is_maximize):
	if is_maximize:
		Utils.set_windows_resizable(false)
	OS.set_window_maximized(is_maximize)
	_check_option_state()

func _on_resize_pressed(bool_resize):
	Utils.set_windows_resizable(bool_resize)

func _on_screen_changed(screen_id):
	OS.current_screen = screen_id

func _exit_tree():
	Utils.set_windows_resizable(false)
