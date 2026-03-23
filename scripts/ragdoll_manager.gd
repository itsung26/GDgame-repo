extends Node
## The ragdoll system is made up of three levels: rigs([Skeleton3D]), sims([PhysicalBone3D]),
## and gibs([PhysicalBone3D]). The system recieves it's rig data from the active [Level].


var ragdoll_rigs:Array[Skeleton3D] = []
var ragdoll_sims:Array[PhysicalBone3D] = []
var ragdoll_gibs:Array[PhysicalBone3D] = []


## Clears all ragdoll data sets
func clearRagdolls() -> void:
	ragdoll_rigs.clear()
	ragdoll_sims.clear()
	ragdoll_gibs.clear()


## Appends a new skeleton(ragdoll rig) to the list of rigs.
func addRagdollRig(new_rig:Skeleton3D) -> void:
	ragdoll_rigs.append(new_rig)


## Removes a rig from the list.
func removeRagdollRig(rig:Skeleton3D) -> void:
	var index:int = ragdoll_rigs.find(rig)
	ragdoll_rigs.remove_at(index)
