class_name PauseMenu extends Control
@onready var resume: Button = $CenterButtons/Resume
@onready var center_buttons: Control = $CenterButtons
@onready var shader_toggle: CheckButton = $OptionsMenu/ShaderToggle
@onready var play: MeshInstance3D = $"../world_parts/Play"
@onready var quit: MeshInstance3D = $"../world_parts/Quit"
@onready var quit_animator: AnimationPlayer = $"../quit_animator"
@onready var quit_confirm: MeshInstance3D = $"../world_parts/wall_quit_confirm/quit_confirm"
@onready var quit_cancel: MeshInstance3D = $"../world_parts/wall_quit_confirm/quit_cancel"
@onready var quit_confirm_capsule_animator: AnimationPlayer = $"../quit_confirm_capsule_animator"
@onready var player: CharacterBody3D = get_tree().current_scene.find_child("Player")
@onready var free_slide_toggle: CheckButton = $OptionsMenu/HBoxContainer/GameplayBox/FreeSlideToggleHolder/FreeSlideToggle

@export var main_menu_scene:PackedScene

@export_category("Mouse Behavior")
@export var lock_mouse_on_exit := true
@export var show_mouse_on_enter := true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	center_buttons.visible = false

# Called when any input is recieved.
func _input(event: InputEvent) -> void:
	if  event is InputEventKey:
		# checks for pause input
		if Input.is_action_just_pressed("pause"):
			pause()

## Pauses the game.
func pause() -> void:
	if not get_tree().paused:
		get_tree().paused = true

## Unpauses the game.
func unpause() -> void:
	if get_tree().paused:
		get_tree().paused = false

## Wrapper method that returns true if the game is paused and false if it is not.
func getPause() -> bool:
	return get_tree().paused
