class_name PauseMenu extends Control

@onready var player: Player = get_tree().get_first_node_in_group("players")

signal paused
signal unpaused

@export var main_menu_scene:PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false

# Called when any input is recieved.
func _input(event: InputEvent) -> void:
	if  event is InputEventKey:
		# checks for pause input
		if Input.is_action_just_pressed("pause"):
			if getPause() == true:
				unpause()
			elif getPause() == false:
				pause()

## Pauses the game.
func pause() -> void:
	if get_tree().paused:
		return
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player.pause_menu.visible = true
	paused.emit()

## Unpauses the game.
func unpause() -> void:
	if not get_tree().paused:
		return
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	player.pause_menu.visible = false
	unpaused.emit()

## Wrapper method that returns true if the game is paused and false if it is not.
func getPause() -> bool:
	return get_tree().paused
