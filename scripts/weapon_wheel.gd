extends Control
@onready var pistol_button = get_node("PistolButton")
@onready var death_screen: Control = $"../DeathScreen"
@onready var player: CharacterBody3D = $"../Player"


var mouse_in_PistolBox:bool = false
var mouse_in_BlackHoleBox:bool = false
enum weapon_wheel_states {OPEN, CLOSED, ITEMHOVER}
var state = weapon_wheel_states.CLOSED

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # ignore

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:

	# change weapon based on the mouse being in the box and releasing tab
	if mouse_in_PistolBox and Input.is_action_just_released("weaponwheel"):
		player.weapon_state = player.weapon_states.PISTOL
	if mouse_in_BlackHoleBox and Input.is_action_just_released("weaponwheel"):
		player.weapon_state = player.weapon_states.BLL
	
	# makes weapon wheel visible
	if Input.is_action_pressed("weaponwheel"):
		state = weapon_wheel_states.OPEN
		player.player_look_input_enabled = false
		player.player_fire_input_enabled = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		visible = true
	
	# makes weapon wheel invisibile
	elif not Input.is_action_pressed("weaponwheel"):
		state = weapon_wheel_states.CLOSED
		player.player_look_input_enabled = true
		player.player_fire_input_enabled = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		visible = false


func _on_pistol_button_mouse_entered() -> void:
	mouse_in_PistolBox = true
	state = weapon_wheel_states.ITEMHOVER


func _on_pistol_button_mouse_exited() -> void:
	mouse_in_PistolBox = false
	state = weapon_wheel_states.ITEMHOVER

func _on_black_hole_button_mouse_entered() -> void:
	mouse_in_BlackHoleBox = true
	state = weapon_wheel_states.ITEMHOVER

func _on_black_hole_button_mouse_exited() -> void:
	mouse_in_BlackHoleBox = false
	state = weapon_wheel_states.ITEMHOVER
