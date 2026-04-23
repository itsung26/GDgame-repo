class_name GrappleHookSweepingCast
extends ShapeCast3D

func _ready() -> void:
	pass


## Sets [code]target_position[/code] to [param point], expecting global coordinates.
func setTargetPositionGlobal(point:Vector3) -> void:
	var point_local:Vector3 = to_local(point)
	target_position = point_local
