@icon("res://assets/2d assets/ui/icons generic/weapon_placeholder.png")
class_name PlayerWeapon
extends Node3D
## Abstract base class for player weapons.

@export var ammo:int
@export var magsize:int
@export var damage_min:float
@export var damage_max:float
@export var automatic:bool

func _ready() -> void:
	print("initialized weapon " + str(self))

func _process(delta: float) -> void:
	pass

func _onEquip():
	print("non-overidden _onEquipt() called.")

func _fire():
	print("non-overidden _fire() called.")
	
func _special():
	print("non-overidden _special() called.")

func _reload():
	print("non-overidden _reload() called.")
