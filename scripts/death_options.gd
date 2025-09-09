extends Node2D

func _ready() -> void:
	pass


func _on_reset_game_pressed() -> void:
	print("restarting game")
	get_tree().quit(0)


func _on_quit_game_pressed() -> void:
	print("game closed: exit code 0")
	get_tree().quit(0)
