class_name HitscanBulletConfig
extends Resource
## Configuration resource for hitscan bullet behavior.
##
## Attach this resource to weapons to define how their bullets behave,
## including damage, visuals, and reflection properties.

@export_group("Damage")
## Minimum damage dealt on hit.
@export var damage_min: float = 10.0
## Maximum damage dealt on hit.
@export var damage_max: float = 15.0
## Type of damage dealt to enemies.
@export var damage_type: Enemy.damage_types = Enemy.damage_types.NORMAL

@export_group("Visuals")
## Scene to instantiate for the bullet trail. Must have a setup(origin, target, color) method.
@export var trail_scene: PackedScene
## Color of the bullet trail.
@export var trail_color: Color = Color.WHITE
## Scene to instantiate for impact particles on world geometry. Must have a setup(position, normal) method.
@export var impact_particle_scene: PackedScene
## Optional scene for impact light effect. Will be positioned at hit point.
@export var impact_light_scene: PackedScene

@export_group("Reflection")
## Whether this bullet can reflect off surfaces.
@export var can_reflect: bool = false
## Maximum number of times the bullet can reflect.
@export var max_reflections: int = 0
## Whether reflected bullets deal reduced damage with each bounce.
@export var use_damage_falloff: bool = true
## Damage multiplier applied per reflection (e.g., 0.5 = 50% damage after first bounce). Only used if use_damage_falloff is enabled.
@export var reflection_damage_falloff: float = 0.5

@export_group("Piercing")
## If true and a DeepRayCast3D is used, the bullet can pierce through multiple enemies/world hits along the ray.
@export var can_pierce_enemies: bool = false


## Returns a random damage value within the configured range.
func get_random_damage() -> float:
	return randf_range(damage_min, damage_max)
