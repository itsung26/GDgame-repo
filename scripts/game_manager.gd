extends Node

@onready var hud: Control = $"../HUD"
@onready var main: Node3D = $".."
@onready var pause: Control = $"../Pause"
@onready var pixel_shader: Sprite2D = $"../PixelShader"
@onready var death_screen: Control = $"../DeathScreen"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	death_screen.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	pass

func endGame():
	print("game ending due to death- switching to death screen")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://scenes/death_options.tscn")
