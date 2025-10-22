extends Area3D


func _on_body_entered(body: Player) -> void:
	body.player_move_input_enabled = true
	body.player_look_input_enabled = true
