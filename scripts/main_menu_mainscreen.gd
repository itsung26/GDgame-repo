class_name MainMenuMainScreen extends Control

var level_select_scene_instance
var options_scene_instance
var credits_scene_instance

func _ready() -> void:
	pass

func _on_play_button_pressed() -> void:
	LoadHandler.loadNewLevel("res://scenes/main menu screens/main_menu_level_select_screen.tscn", false)

func _on_options_pressed() -> void:
	pass
	

func _on_credits_pressed() -> void:
	pass

func _on_quit_pressed() -> void:
	get_tree().quit()
