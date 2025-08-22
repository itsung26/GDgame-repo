extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

var ispaused = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	
	if Global.current_weapon == "pistol":
		Global.current_special_property = Global.pistol_special_property
	elif Global.current_weapon == "shotgun":
		Global.current_special_property = Global.shotgun_special_property
	
	if Input.is_action_just_pressed("forcequit"):
		'''
		once about every 50 runs or so, this crashes the entire engine,
		editor and all to a black screen, sometimes even crashing task manager, godot is so stable.
		'''
		get_tree().quit()

	if Input.is_action_just_pressed("pause"):
		if not ispaused:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_tree().paused = true
			ispaused = true
		elif ispaused:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			get_tree().paused = false
			ispaused = false
