class_name MainMenuLevelSelectScreen extends Control

func _ready() -> void:
	pass

func _on_back_button_pressed() -> void:
	LoadHandler.loadNewLevel("res://scenes/main menu screens/main_menu_mainscreen.tscn", false)
	
# 0-1: loads the center
func _on_mission_button_01_pressed() -> void:
	LoadHandler.loadNewLevel("res://scenes/maps/the_center.tscn")


func _on_mission_button_11_pressed() -> void:
	LoadHandler.loadNewLevel("res://scenes/maps/the_cold_winds.tscn")
