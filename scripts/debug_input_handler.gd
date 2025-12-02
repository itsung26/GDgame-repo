## An autoload singleton to call methods when input keys are pressed.
extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_P):
		var player:Player = Helper.getFirstInScene("Player")
		var player_camera:PlayerCamera = player.camera_3d
		player_camera.shakeCamera(0.8, 2.5 / 2)
		
		
	if Input.is_key_pressed(KEY_QUOTELEFT): # (`) key
		print("debugforcequit")
		if get_tree():
			get_tree().quit()
		else:
			print("ERROR: attempted a force quit before the scene tree became active")
