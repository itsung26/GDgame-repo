extends Button
@onready var pistol_button: Button = $WheelCore/PistolButton
@onready var black_hole_button: Button = $WheelCore/BlackHoleButton

var self_style
var mouse_in_box:bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if mouse_in_box and Input.is_action_just_released("weaponwheel"):
		print("switching to weapon")
