extends Node


func _on_play_button_pressed() -> void:
	var button:Button = Helper.getFirstInScene("playButton")
	print("WIP")

func _on_options_pressed() -> void:
	var button:Button = Helper.getFirstInScene("optionsButton")
	print("WIP")

func _on_credits_pressed() -> void:
	var button:Button = Helper.getFirstInScene("creditsButton")
	print("WIP")

func _on_quit_pressed() -> void:
	var button:Button = Helper.getFirstInScene("quitButton")
	print("quitting")
	get_tree().quit()
	
