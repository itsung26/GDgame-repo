class_name ImpactHammer
extends PlayerWeapon
## One-handed boom hammer. The faster the player is traveling, the more damage it does.
## Above a certain speed, impact will cause an explosion chain.


func _onEquipImpl() -> void:
	Debug.log("impact hammer equipped")


func _fireImpl() -> void:
	pass


func _specialImpl() -> void:
	pass


func _specialReleaseImpl() -> void:
	pass


func _reloadImpl() -> void:
	pass


func _process(delta: float) -> void:
	pass # replace with main behavior
