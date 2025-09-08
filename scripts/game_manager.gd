extends Node

@onready var hud: Control = $"../HUD"
@onready var main: Node3D = $".."
@onready var pause: Control = $"../Pause"
@onready var pixel_shader: Sprite2D = $"../PixelShader"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	return

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	
	if Input.is_action_just_pressed("forcequit"):
		get_tree().quit()
	
	# enables and disables every frame
	if Global.isPaused:
		hud.visible = false
	elif not Global.isPaused:
		hud.visible = true
		
	if Global.enableShader:
		pixel_shader.visible = true
	else:
		pixel_shader.visible = false
	
	if Input.is_action_just_pressed("pause"):
		
		if not Global.isPaused:
			pauseGame()
		
		elif Global.isPaused:
			unpauseGame()


func pauseGame():
	print("pausing")
	Global.menuState = "main"
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true
	Global.isPaused = true
	Global.menuState = "main"

	
func unpauseGame():
	print("unpausing")
	pause.visible = false
	Global.menuState = "notpaused"
	Global.isPaused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().paused = false

func endGame():
	print("game ending due to death- switching to death screen")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://scenes/death_options.tscn")
