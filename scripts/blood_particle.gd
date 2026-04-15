class_name BloodParticle
extends PhysicalParticle

@onready var blood_particle_trail: VaporTrail = %BloodParticleTrail

@export var decal_scene:PackedScene
## At 0.0, no particles will have a trail. At 1.0, all particles will have a trail.
@export var chance_to_have_trail:float = 0.50

var last_physics_state:PhysicsDirectBodyState3D


func _ready() -> void:
	if not DecalPool.is_pool_registered(decal_scene):
		DecalPool.register_pool(decal_scene, 1000)
	var random:float = randf_range(0.0, 1.0)
	if random <= chance_to_have_trail:
		pass
	else:
		blood_particle_trail.visible = false
		blood_particle_trail.queue_free()


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	last_physics_state = state


## Same idea as [method Node3D.look_at], but [param front] is [param looker]'s local axis that should
## point toward [param target] (Godot default forward is [code](0,0,-1)[/code]).
func lookAtFront(looker:Node3D, target:Vector3, up:Vector3 = Vector3.ZERO, front:Vector3 = Vector3(0, 0, -1)) -> void:
	var f:Vector3 = front.normalized()
	var world_dir:Vector3 = (target - looker.global_position).normalized()
	if world_dir.length_squared() < 0.0000001:
		return
	var up_vec:Vector3 = up if up.length_squared() > 0.0001 else Vector3.UP
	up_vec = up_vec.normalized()
	if abs(world_dir.dot(up_vec)) > 0.999:
		up_vec = Vector3.RIGHT.cross(world_dir).normalized()
		if up_vec.length_squared() < 0.000001:
			up_vec = Vector3.FORWARD.cross(world_dir).normalized()
	var basis_default:Basis = Basis.looking_at(world_dir, up_vec)
	var default_front:Vector3 = Vector3(0, 0, -1)
	var a:Vector3 = f
	var b:Vector3 = default_front
	var align_dot:float = a.dot(b)
	var r_local:Basis
	if align_dot > 0.99999:
		r_local = Basis()
	elif align_dot < -0.99999:
		var axis_pi:Vector3 = Vector3.RIGHT.cross(a).normalized()
		if axis_pi.length_squared() < 0.0001:
			axis_pi = Vector3.UP.cross(a).normalized()
		r_local = Basis(axis_pi, PI)
	else:
		var axis:Vector3 = a.cross(b).normalized()
		var angle:float = acos(clampf(align_dot, -1.0, 1.0))
		r_local = Basis(axis, angle)
	looker.global_transform = Transform3D(basis_default * r_local, looker.global_position)


func spawnDecal(pos:Vector3, normal:Vector3, rot:float) -> void:
	var blood_decal:Decal = DecalPool.request(decal_scene)
	get_tree().current_scene.add_child(blood_decal)
	var n:Vector3 = normal.normalized()
	blood_decal.global_position = pos
	lookAtFront(blood_decal, blood_decal.global_position + n, Vector3.UP, Vector3(0.0, 1.0, 0.0))
	blood_decal.global_rotate(n, rot)
	var x:float = randf_range(1.0, 2.0)
	blood_decal.size *= x


func _on_body_entered(body: Node) -> void:
	freeze = true
	visible = false
	
	# check to make sure the body has a valid contact (it always should)
	if get_contact_count() < 1:
		return
	
	# store the collision point on the collider and the self particle
	var hit_pos_on_hit_thing:Vector3 = last_physics_state.get_contact_collider_position(0)
	var hit_pos_on_self:Vector3 = last_physics_state.get_contact_local_position(0)
	
	# store the median between the two points for the most accurate spawning point
	var particle_spawn_pos:Vector3 = (hit_pos_on_hit_thing + hit_pos_on_self) / 2
	# store the normal of the collider looking AWAY from
	var particle_spawn_normal:Vector3 = last_physics_state.get_contact_local_normal(0).normalized()
	# store a random rotation
	var particle_random_rotation:float = randf_range(0.0, 2 * PI)
	
	spawnDecal(particle_spawn_pos, particle_spawn_normal, particle_random_rotation)
