extends Control

func _ready() -> void:
	visible = false
	


func _on_timer_timeout() -> void:
	visible = true
