class_name PauseMenu extends Control
## Pause menu UI. Handles pause/unpause input and toggles visibility.

@onready var player: Player = get_tree().get_first_node_in_group("players")
@onready var main_center_pause: UICollapseTweener = $CenterButtons/MainCenterPause
@onready var restart_confirm: UICollapseTweener = $CenterButtons/RestartConfirm

enum menu_states {UNPAUSED, MAINPAUSE, RESTARTCONFIRM, QUITCONFIRM, OPTIONS}

signal paused
signal unpaused

@export var main_menu_scene: PackedScene

var menu_panels:Array[Control] =[]
var menu_state: menu_states: set = setMenuState


func setMenuState(new_menu_state:menu_states):
	var previous_menu_state:menu_states = menu_state
	menu_state = new_menu_state
	
	if previous_menu_state == new_menu_state:
		return
	
	## UNPAUSED
	if new_menu_state == menu_states.UNPAUSED:
		player.pause_menu.visible = false
	if previous_menu_state == menu_states.UNPAUSED:
		player.pause_menu.visible = true
	
	## MAINPAUSE
	if new_menu_state == menu_states.MAINPAUSE:
		main_center_pause.expandVertical()
	if previous_menu_state == menu_states.MAINPAUSE:
		main_center_pause.collapseVertical()
	
	## RESTARTCONFIRM
	if new_menu_state == menu_states.RESTARTCONFIRM:
		restart_confirm.expandVertical()
	if previous_menu_state == menu_states.RESTARTCONFIRM:
		restart_confirm.collapseVertical()


func _ready() -> void:
	visible = false
	menu_panels.append_array(get_tree().get_nodes_in_group("pause menu panels"))
	setMenuState(menu_states.UNPAUSED)


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if Input.is_action_just_pressed("pause"): # WHEN PAUSE KEY PRESSED
			if get_pause(): # IF ALREADY PAUSED
				setMenuState(menu_states.UNPAUSED)
				unpause()
			else: # IF NOT PAUSED
				pause()
				setMenuState(menu_states.MAINPAUSE)


func _process(delta: float) -> void:
	Debug.log(str(menu_states.keys()[menu_state]))
	
	
## Pauses the game.
func pause() -> void:
	if get_tree().paused:
		return
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	paused.emit()


## Unpauses the game.
func unpause() -> void:
	if not get_tree().paused:
		return
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	unpaused.emit()



## Returns true if the game is paused, false otherwise.
func get_pause() -> bool:
	return get_tree().paused


func _on_resume_pressed() -> void:
	setMenuState(menu_states.UNPAUSED)
	unpause()


func _on_options_pressed() -> void:
	pass # Replace with function body.


func _on_restart_pressed() -> void:
	setMenuState(menu_states.RESTARTCONFIRM)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_restart_confirm_pressed() -> void:
	LoadHandler.reloadCurrentLevel()


func _on_restart_cancel_pressed() -> void:
	setMenuState(menu_states.MAINPAUSE)
