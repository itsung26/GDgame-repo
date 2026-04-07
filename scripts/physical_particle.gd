class_name PhysicalParticle
extends RigidBody3D

@export var hiding_on_collide:bool = false


func _ready() -> void:
	connect("body_entered", _on_body_entered)


func _on_body_entered(body: Node) -> void:
	if hiding_on_collide:
		visible = false
		freeze = true
