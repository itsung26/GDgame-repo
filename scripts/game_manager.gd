extends Node
@onready var ammo_counter: Label = $"../HUD/ammoCounter"
@onready var pistol: Skeleton3D = $Pivot/Camera3D/pistol


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

var ispaused = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	
	if Input.is_action_just_pressed("forcequit"):
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
