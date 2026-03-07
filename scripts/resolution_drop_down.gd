class_name ResolutionDropDown
extends SettingsDropdown


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var cfg_read_resolution:Vector2i = getResolutionRich()
	# get the index of the item that contains that resolution
	var index:int = getResDropdownIndex(cfg_read_resolution)
	selectItem(index)


## Returns the index of [param resolution] in the dropdown's items.
func getResDropdownIndex(resolution: Vector2i) -> int:
	match resolution:
		Vector2i(1920, 1080):
			return 0
		Vector2i(1152, 648):
			return 1
	return -1


## Returns the screen resolution read from the config formatted as a [Vector2i].
func getResolutionRich() -> Vector2i:
	var isize_x:int = CfgParser.get_int("display", "resolution_width")
	var isize_y:int = CfgParser.get_int("display", "resolution_height")
	return Vector2i(isize_x, isize_y)


## Sets both resolution properties in the cfg
func setCfgResolution(res:Vector2i) -> void:
	var isize_x:int = res.x
	var isize_y:int = res.y
	CfgParser.set_int("display", "resolution_width", isize_x)
	CfgParser.set_int("display", "resolution_height", isize_y)


func selectItem(index:int) -> void:
	select(index)
	match index:
		0: # 1920 x 1080
			var newRes:Vector2i = Vector2i(1920, 1080)
			DisplayServer.window_set_size(newRes)
			setCfgResolution(newRes)
		1: # 1152 x 648
			var newRes:Vector2i = Vector2i(1152, 648)
			DisplayServer.window_set_size(newRes)
			setCfgResolution(newRes)

func _on_item_selected(index: int) -> void:
	selectItem(index)
	CfgParser.save()
