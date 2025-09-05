extends Control
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	var R_or_L_anim:int = randi_range(0,1)
	if R_or_L_anim == 0:
		animation_player.play("falloff_right")
	elif R_or_L_anim == 1:
		animation_player.play("falloff_left")
