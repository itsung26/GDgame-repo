@tool
class_name PhysicalParticleEmitter
extends Node3D
## This object acts as a cpu-based particle emitter. Note that it directly instances
## scenes as particles and therefore 

@export_category("Particle Instancing")
## The scene that is instanced. Note that the scene selected MUST have a [PhysicalParticle] as the root node.
@export var particle_SCENE:PackedScene
## Determines the amount of instances allocated to pool memory. This number must be greater than 0, and should not be too high for complex particle scenes.
@export var pool_allocations:int = 1

@export_group("Particle Process Behavior")
@export var particle_lifetime:float = 1.0
@export var one_shot:bool = false

@export_group("Velocity")
## The direction of emission. Expects a normalized vector
@export var direction:Vector3 = Vector3(1.0, 0.0, 0.0)
@export var velocity:float = 0.0

var _particle_pool:Array[PhysicalParticle]

func _ready() -> void:
	_allocate_pool_instances(particle_SCENE)


func _process(delta: float) -> void:
	pass


func _allocate_pool_instances(scene:PackedScene, amount:int) -> void:
	
