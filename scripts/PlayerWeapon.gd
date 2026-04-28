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


func onEquip() -> void:
	equipped.emit()
	_onEquipImpl()


func fire() -> void:
	fired.emit()
	_fireImpl()


func special() -> void:
	special_triggered.emit()
	_specialImpl()


func specialRelease() -> void:
	special_released.emit()
	_specialReleaseImpl()


func reload() -> void:
	reloaded.emit()
	_reloadImpl()


@abstract
func _onEquipImpl() -> void


@abstract
func _fireImpl() -> void


@abstract
func _specialImpl() -> void


@abstract
func _specialReleaseImpl() -> void


@abstract
func _reloadImpl() -> void
