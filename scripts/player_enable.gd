extends Area3D
@onready var level_title: Control = $"../../../LevelTitle"
@onready var timer: Timer = $"../../../LevelTitle/Timer"

func _on_body_entered(body: Player) -> void:
	body.player_move_input_enabled = true
	body.player_look_input_enabled = true
	level_title.visible = true
	timer.start(2.0)
