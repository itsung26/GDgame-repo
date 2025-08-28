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
		
		# pauses======================================================================================
		if not Global.isPaused:
			Global.menuState = "main"
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_tree().paused = true
			Global.isPaused = true
			Global.menuState = "main"
			
		# unpauses=======================================================================================
		elif Global.isPaused:
			pause.visible = false
			print("unpausing")
			Global.menuState = "notpaused"
			Global.isPaused = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			get_tree().paused = false
