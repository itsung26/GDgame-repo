extends Control
@onready var pistol_button = get_node("PistolButton")
@onready var death_screen: Control = $"../DeathScreen"


var mouse_in_PistolBox:bool = false
var mouse_in_BlackHoleBox:bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	# change weapon based on the mouse being in the box and releasing tab
	if mouse_in_PistolBox and Input.is_action_just_released("weaponwheel"):
		Global.current_weapon = "pistol"
	if mouse_in_BlackHoleBox and Input.is_action_just_released("weaponwheel"):
		Global.current_weapon = "BLL"
	
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


func _on_pistol_button_mouse_entered() -> void:
	mouse_in_PistolBox = true


func _on_pistol_button_mouse_exited() -> void:
	mouse_in_PistolBox = false


func _on_black_hole_button_mouse_entered() -> void:
	mouse_in_BlackHoleBox = true


func _on_black_hole_button_mouse_exited() -> void:
	mouse_in_BlackHoleBox = false
