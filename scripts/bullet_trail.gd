@tool
class_name BulletTrail
extends MeshInstance3D

var shrinking_y:bool = false
@export var shrink_curve:Curve
var x:int = 0

func _init() -> void:
	pass

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if shrinking_y:
		print(shrink_curve.sample_baked(x))
		mesh.size.y = shrink_curve.sample(x)
		x += 1

func setup(origin_pos:Vector3, target_pos:Vector3, color:Color = Color.WHITE):
	var distance_to_target_pos:float
	global_position = (origin_pos + target_pos) / 2
	look_at(target_pos)
	shrinking_y = true
	mesh.size.x = origin_pos.distance_to(target_pos)
