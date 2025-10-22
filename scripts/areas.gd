## Handler for area signals
extends Node3D
@onready var pedestal_animation: AnimationPlayer = $"../PistolPedestal/PedestalAnimation"


func _on_pistol_obtain_body_entered(player: Player) -> void:
	print(str(player) + " entered pedestal collider, giving pistol and lowering")
	player.pistol_switch_enabled = true
	player.weapon_state = player.weapon_states.PISTOL
	pedestal_animation.play("lower")
