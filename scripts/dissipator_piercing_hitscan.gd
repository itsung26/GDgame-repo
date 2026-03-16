@tool
class_name DissipatorPiercingHitscan
extends DeepRayCast3D
# base script path: res://addons/deep_raycast_3d/deep_raycast_3d.gd


## Returns an array of all colliding bodies.
func getColliders() -> Array[Node3D]:
	var ret: Array[Node3D] = []
	var count := get_collider_count()
	if count == 0:
		return ret
	for i in range(count):
		var collider := get_collider(i)
		if collider is Node3D:
			ret.append(collider)
	return ret


## Returns an array of all colliding enemies.
func getEnemyColliders() -> Array[Enemy]:
	var ret: Array[Enemy] = []
	var colliders: Array[Node3D] = getColliders()
	if colliders.is_empty():
		return ret
	for collider in colliders:
		if collider is Enemy:
			ret.append(collider as Enemy)
	return ret
