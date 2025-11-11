extends Node

@export var player:Player

func onStart():
	player.player_kinematics_enabled_xz = true
	player.player_kinematics_enabled_y = true
