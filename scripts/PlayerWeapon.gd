@icon("res://weapon_placeholder.png")
class_name PlayerWeapon
extends Node3D

## Abstract base class for player weapons.

signal equipped
signal fired
signal special_triggered
signal reloaded
signal special_released

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

func _fire() -> void:
	fired.emit()
	
func _special() -> void:
	special_triggered.emit()

func _specialRelease() -> void:
	special_released.emit()

func _reload() -> void:
	reloaded.emit()
