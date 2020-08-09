tool
extends SelectablePanelContainer
class_name RoundedSelectablePanelRight


func _draw():
	if has_focus():
		var theme_style = get_stylebox("focus_style", "RoundedSelectablePanelRight")
		var style = focus_style if focus_style!= null else theme_style
		if style != null:
			focus_style.draw(get_canvas_item(), get_rect())


func update_style():
	if is_selected:
		var theme_style = get_stylebox("selected_style", "RoundedSelectablePanelRight")
		set("custom_styles/panel", selected_style if selected_style != null else theme_style)
	elif _hover:
		var theme_style = get_stylebox("hover_style", "RoundedSelectablePanelRight")
		set("custom_styles/panel", hover_style if hover_style != null else theme_style)
	else:
		var theme_style = get_stylebox("base_style", "RoundedSelectablePanelRight")
		set("custom_styles/panel", base_style if base_style != null else theme_style)
	update()
