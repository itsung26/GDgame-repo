extends Node2D

func _ready() -> void:
	pass


func _on_reset_game_pressed() -> void:
	pass # Replace with function body.


func _on_quit_game_pressed() -> void:
	print("game closed: exit code 0")
	get_tree().quit(0)
