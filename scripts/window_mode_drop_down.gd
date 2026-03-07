class_name WindowModeDropDown
extends SettingsDropdown

@onready var resolution_drop_down: ResolutionDropDown = $"../ResolutionDropDown"


func _ready() -> void:
	var initial_index:int = getUserSettingsIndex("display", "window_mode")
	selectItem(initial_index)


func _on_item_selected(index: int) -> void:
	selectItem(index)
	CfgParser.save()
	
	
func selectItem(index:int) -> void:
	select(index)
	match index:
		0: # borderless
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			get_window().borderless = true
			DisplayServer.window_set_size(resolution_drop_down.getResolutionRich())
			resolution_drop_down.getResolutionRich()
			centerWindow()
			CfgParser.set_string("display", "window_mode", "borderless")
		1: # Fullscreen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			get_window().borderless = true
			CfgParser.set_string("display", "window_mode", "fullscreen")
		2: # Windowed
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			get_window().borderless = false
			DisplayServer.window_set_size(resolution_drop_down.getResolutionRich())
			centerWindow()
			CfgParser.set_string("display", "window_mode", "windowed")

## Centers the window on the screen.
func centerWindow() -> void:
	var win := get_window()
	if win == null:
		return
	win.move_to_center()
