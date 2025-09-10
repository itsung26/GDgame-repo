extends Node3D
@onready var open_and_delete: AnimationPlayer = $BlackHoleAmmo/OpenAndDelete
@onready var black_hole_emitter: GPUParticles3D = $BlackHoleEmitter

var can_add_ammo:bool = true
var has_full_mag:bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	black_hole_emitter.emitting = false

func _process(_delta:float) -> void:
	if Global.BLL_ammo == 3:
		has_full_mag = true
	elif Global.BLL_ammo < 3:
		has_full_mag = false
		

func _on_black_hole_ammo_body_entered(_body: CharacterBody3D) -> void:
	if can_add_ammo and not has_full_mag:
		Global.BLL_ammo += 1
		can_add_ammo = false
		open_and_delete.play("ammo box open and delete")
