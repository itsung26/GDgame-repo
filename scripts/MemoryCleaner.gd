extends Node

## This singleton Keeps a database of objects drawn and watches for memory leaks.
## It is capable of attempting cleanups and garbage collection, but in general scenes
## should handle their own cleanup in order to keep their memory dependencies internal.

static var projectiles_drawn:Array[EnemyProjectile] = []
static var gib_limbs_drawn:Array[Node3D] = []

func registerProjectile(projectile:EnemyProjectile) -> void:
	projectiles_drawn.append(projectile)

func registerGibLimb(gibbed_limb:PhysicalBone3D) -> void:
	gib_limbs_drawn.append(gibbed_limb)
