@icon("res://weapon_placeholder.png")
class_name PlayerWeapon
extends Node3D

## Abstract base class for player weapons.

signal equipped
signal fired
signal special_triggered
signal reloaded

@export var ammo:int
@export var magsize:int
@export var damage_min:float
@export var damage_max:float
@export var automatic:bool

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func _onEquip() -> void:
	equipped.emit()
	print("non-overidden _onEquipt() called.")

func _fire() -> void:
	fired.emit()
	print("non-overidden _fire() called.")
	
func _special() -> void:
	special_triggered.emit()
	print("non-overidden _special() called.")

func _reload() -> void:
	reloaded.emit()
	print("non-overidden _reload() called.")
