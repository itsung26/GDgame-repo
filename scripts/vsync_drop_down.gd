extends SettingsDropdown


## Get the index of the item to select in the dropdown from the initial user setting.
func _ready() -> void:
	var initial_index:int = getUserSettingsIndex("display", "vsync_mode")
	selectItem(initial_index)


func _on_vsync_drop_down_item_selected(index: int) -> void:
	selectItem(index)
	CfgParser.save()


func selectItem(index:int) -> void:
	select(index)
	match index:
		0: # disabled
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
			CfgParser.set_string("display", "vsync_mode", "disabled")
		1: # enabled
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
			CfgParser.set_string("display", "vsync_mode", "enabled")
		2: # adaptive
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ADAPTIVE)
			CfgParser.set_string("display", "vsync_mode", "adaptive")
