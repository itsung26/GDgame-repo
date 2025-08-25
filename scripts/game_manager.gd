extends Node

@onready var hud: Control = $"../HUD"
@onready var main: Node3D = $".."
@onready var pause: Control = $"../Pause"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	return

var ispaused = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	
	if Global.current_weapon == "pistol":
		Global.current_special_property = Global.pistol_special_property
	elif Global.current_weapon == "shotgun":
		Global.current_special_property = Global.shotgun_special_property
	
	if Input.is_action_just_pressed("forcequit"):
		get_tree().quit()
	
	if Input.is_action_just_pressed("pause"):
		
		# pauses======================================================================================
		if not ispaused:
			pause.visible = true
			hud.visible = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_tree().paused = true
			ispaused = true
			
		# unpauses=======================================================================================
		elif ispaused:
			pause.visible = false
			hud.visible = true
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			get_tree().paused = false
			ispaused = false
