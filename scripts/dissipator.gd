class_name PlayerDissipator
extends PlayerWeapon

const bullet_trail_SCENE:PackedScene = preload("res://scenes/bullet_trail.tscn")
const BULLET_IMPACT_PARTICLE_SCENE_2:PackedScene = preload("res://scenes/bullet_impact_particles_2.tscn")

@onready var animation_player: AnimationPlayer = $Dissipator2/AnimationPlayer
@onready var muzzle: Node3D = $Dissipator2/feedbacker/Skeleton3D/Hand/Dissipator/muzzle
@onready var dissipator_hitscan: RayCast3D = $DissipatorHitscan


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	pass


func _onEquip() -> void:
	super._onEquip()
	animation_player.play("Equip")


func _fire() -> void:
	super._fire()
	fireBullet()
	Debug.log("foo")


func _special() -> void:
	super._special()


func _specialRelease() -> void:
	super._specialRelease()


func _reload() -> void:
	super._reload()


func fireBullet() -> void:
	var hit_body:Node3D = dissipator_hitscan.get_collider()
	var hit_surface_normal:Vector3 = dissipator_hitscan.get_collision_normal()
	var hit_point:Vector3 = dissipator_hitscan.get_collision_point()
	if not hit_body:
		hit_point = dissipator_hitscan.to_global(dissipator_hitscan.target_position)
	
	var bullet_trail:BulletTrail = bullet_trail_SCENE.instantiate()
	get_tree().current_scene.add_child(bullet_trail)
	bullet_trail.setup(muzzle.global_position, hit_point, Color.YELLOW)
	
	# Register the actual damage part of the gun
	# cases for each thing that could be hit
	if hit_body is Enemy:
		hit_body.damageEnemy(randf_range(damage_max, damage_max), Enemy.damage_types.NORMAL)
	elif hit_body is PistolBomb:
		var player:Player = get_tree().get_first_node_in_group("players")
		player.hitStop(hit_body.hitstop_duration_on_being_shot)
		var parry_visuals:Array[Node] = get_tree().get_nodes_in_group("parry visuals")
		for parry_visual in parry_visuals:
			if parry_visual.name == "ParryFlash":
				pass
			else:
				parry_visual.visible = true
		hit_body.explode()
	else:
		# add an impact particle to the scene where the bullet hit
		# go to hit point and look at surface normal
		var bullet_impact_particle_2 = BULLET_IMPACT_PARTICLE_SCENE_2.instantiate()
		get_tree().current_scene.add_child(bullet_impact_particle_2)
		bullet_impact_particle_2.setup(hit_point, hit_surface_normal)
