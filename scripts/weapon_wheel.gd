extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	# makes weapon wheel visible
	if Input.is_action_pressed("weaponwheel"):
		Global.player_look_input_enabled = false
		Global.player_fire_input_enabled = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		visible = true
	
	# makes weapon wheel invisibile
	else:
		Global.player_look_input_enabled = true
		Global.player_fire_input_enabled = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		visible = false
