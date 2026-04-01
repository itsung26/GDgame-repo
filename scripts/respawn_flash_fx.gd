class_name RespawnFlashFx
extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func setup() -> void:
	animation_player.play("fade_out")
