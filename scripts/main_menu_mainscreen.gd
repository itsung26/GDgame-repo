extends Node3D

func _ready() -> void:
	pass
	
func _process(delta: float) -> void:
	pass
	
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("forcequit"):
		get_tree().quit()
