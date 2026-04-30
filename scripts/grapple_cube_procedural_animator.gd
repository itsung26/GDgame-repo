@tool
extends Node3D

@onready var outermost_joint: Node3D = $"../outermost_joint"
@onready var mid_joint: Node3D = $"../mid_joint"
@onready var inner_joint: Node3D = $"../inner_joint"

@export var active:bool = false
@export var master_speed_multiplier:float = 1.0
@export var outermost_rotation_speed:float = 1.0
@export var mid_rotation_speed:float = 1.0
@export var innermost_rotation_speed:float = 1.0

var joints:Array[Node3D]


func _ready() -> void:
	joints.append_array([outermost_joint, mid_joint, inner_joint])
	for joint:Node3D in joints:
		joint.rotation = Vector3.ZERO


func _process(delta: float) -> void:
	if not active:
		return

	var joint_count:int = joints.size()
	for joint_idx:int in range(joint_count):
		var speed:float = _getJointSpeed(joint_idx) * master_speed_multiplier
		if speed == 0.0:
			continue

		joints[joint_idx].rotation += _getJointAxis(joint_idx) * speed * delta


func _getJointSpeed(joint_idx:int) -> float:
	if joint_idx == 0:
		return outermost_rotation_speed
	if joint_idx == 1:
		return mid_rotation_speed
	return innermost_rotation_speed


func _getJointAxis(joint_idx:int) -> Vector3:
	if joint_idx == 0:
		return Vector3.UP
	if joint_idx == 1:
		return Vector3.RIGHT
	return Vector3.FORWARD
