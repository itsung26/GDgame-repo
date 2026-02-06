class_name SlideParticles
extends Node3D

@onready var player: CharacterBody3D = $".."
@onready var slide_light: OmniLight3D = $ImpactParticles/SlideLight
@onready var impact_sparks: GPUParticles3D = $ImpactParticles/SparkTrailsSide/ImpactSparks
@onready var impact_sparks_2: GPUParticles3D = $ImpactParticles/SparkTrailsSide/ImpactSparks2
@onready var impact_particles: GPUParticles3D = $ImpactParticles

func _process(delta: float) -> void:
	var direction = player.velocity.normalized()
	if direction != Vector3.ZERO:
		look_at(global_position + direction, Vector3.UP + Vector3(0.0001, 0.0001, 0.0001))
