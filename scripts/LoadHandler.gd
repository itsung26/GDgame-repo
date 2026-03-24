## Handles loading and unloading levels.
extends Node

const loading_icon_scene_path:String = "res://scenes/main menu screens/loading_label.tscn"
var loading_icon_scene_master:PackedScene = preload(loading_icon_scene_path)
var delay_timer:Timer = Timer.new()
var current_level:Level:
	set = setCurrentLevel


func _ready() -> void:
	current_level = getCurrentLevel()


func setCurrentLevel(value:Level) -> void:
	current_level = value


func getCurrentLevel() -> Level:
	if get_tree().current_scene is Level:
		return get_tree().current_scene
	else:
		return null


## Loads the new scene at new_scene_path, adds the loading icon the the scene if showLoadingIcon is true after waiting a few frames.
func loadNewLevel(new_scene_path:String, showLoadingIcon:bool = true, frames_delay:int = 3) -> void:
	# if the icon is enabled, instance it and add it to the scene
	if showLoadingIcon:
		var x = loading_icon_scene_master.instantiate()
		get_tree().current_scene.add_child(x)

	# wait N render frames (frame‑accurate)
	for i in range(frames_delay):
		await get_tree().process_frame

	# change scene (still deferred to be safe)
	get_tree().call_deferred("change_scene_to_file", new_scene_path)
	call_deferred("setCurrentLevel", get_tree().current_scene)


func reloadCurrentLevel() -> void:
	var plr:Player = get_tree().get_first_node_in_group("players")
	plr.pause_menu.unpause()
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


## Triggers a save state (to be implemented) and then an immidiate application exit.
func quitGame() -> void:
	get_tree().quit()
