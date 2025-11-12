## An autoload singleton to call methods when input keys are pressed.
extends Node



func _input(event: InputEvent) -> void:
	pass
		
	if Input.is_key_pressed(KEY_QUOTELEFT): # (`) key
		print("debugforcequit")
		if get_tree():
			get_tree().quit()
		else:
			print("ERROR: attempted a force quit before the scene tree became active")
