@tool
class_name GrappleRopeLine
extends Line3D

@onready var rope_origin: BoneAttachment3D = $"../Pivot/Camera3D/GrappleArm/grappleArm/whiplash_ARM/Skeleton3D/rope_origin"
@onready var hook_smd: MeshInstance3D = $"../Pivot/Camera3D/GrappleArm/grappleArm/whiplash_ARM/Skeleton3D/rope_origin/GrappleHook/hook_smd"

func _process(delta: float) -> void:
	point_a = to_local(rope_origin.global_position)
	point_b = to_local(hook_smd.global_position)
