class_name levelTeleporter extends Node3D

@export_category("General")
@export var enabled:bool = true:
	set = setEnable
var time_before_teleport:float = 3.0
@export var target_scene:PackedScene

@export_category("Refs")
@export var teleport_timer: Timer
@export var animation_player_fade:AnimationPlayer
@export var whitescreen_rect:ColorRect
@export var collider:CollisionShape3D
@export var cylinder_mesh:MeshInstance3D

var teleporting_player:bool = false
@onready var visibility_group:Array[Node] = get_tree().get_nodes_in_group("visibility")

func setEnable(new_enable_state:bool):
	enabled = new_enable_state
	
	if new_enable_state == false:
		for node:Node3D in visibility_group:
			node.visible = false
		collider.disabled = true
		cylinder_mesh.visible = false

	elif new_enable_state == true:
		collider.disabled = false
		cylinder_mesh.visible = true

func _on_interaction_area_body_entered(player: Player) -> void:
	teleporting_player = true
	teleport_timer.start(time_before_teleport)
	animation_player_fade.play("fade_in")
	for node:Node3D in visibility_group:
		node.visible = true

func _on_interaction_area_body_exited(player: Player) -> void:
	teleporting_player = false
	animation_player_fade.play("go_to_transparent")
	teleport_timer.stop()
	for node:Node3D in visibility_group:
		node.visible = false


func _on_teleport_timer_timeout() -> void:
	get_tree().change_scene_to_packed(target_scene)
