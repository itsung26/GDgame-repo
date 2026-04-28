@abstract
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
var can_fire:bool = true


func _notification(what: int) -> void:
	pass


@abstract
func _onEquip() -> void


@abstract
func _fire() -> void


@abstract
func _special() -> void


@abstract
func _specialRelease() -> void


@abstract
func _reload() -> void
