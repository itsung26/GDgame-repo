class_name debugVisuals extends Node
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var debug_floor: MeshInstance3D = $debugFloor

@export var remove_floor_on_startup:bool = true
@export var remove_body_on_startup:bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if remove_body_on_startup:
		mesh_instance_3d.queue_free()
	if remove_floor_on_startup:
		debug_floor.queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
