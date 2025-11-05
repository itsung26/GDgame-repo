## An autoload singleton to call methods when input keys are pressed.
extends Node

func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_P):
		print("reloading scene")
		get_tree().reload_current_scene()
		
	if Input.is_key_pressed(KEY_QUOTELEFT): # (`) key
		print("debugforcequit")
		if get_tree():
			get_tree().quit()
		else:
			print("ERROR: attempted a force quit before the scene tree became active")
