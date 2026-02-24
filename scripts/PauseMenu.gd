class_name PauseMenu extends Control
## Pause menu UI. Handles pause/unpause input and toggles visibility.

@onready var player: Player = get_tree().get_first_node_in_group("players")
@onready var pause_buttons: UICollapseTweener = $CenterButtons/PauseButtons

signal paused
signal unpaused

@export var main_menu_scene: PackedScene

var menu_panels:Array[Control] =[]


func _ready() -> void:
	visible = false
	menu_panels.append_array(get_tree().get_nodes_in_group("pause menu panels"))


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if Input.is_action_just_pressed("pause"):
			if get_pause():
				unpause()
				pause_buttons.expandVertical()
			else:
				pause_buttons.collapseVertical()
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



## Returns true if the game is paused, false otherwise.
func get_pause() -> bool:
	return get_tree().paused


func _on_resume_pressed() -> void:
	unpause()


func _on_options_pressed() -> void:
	pass # Replace with function body.


func _on_restart_pressed() -> void:
	unpause()
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	get_tree().quit()
