extends Node3D

@onready var laser_wall: LaserWall = $LaserWall
@onready var laser_wall_2: LaserWall = $LaserWall2
@onready var laser_wall_3: LaserWall = $LaserWall3

@export var wall1_starts_on: bool = true
@export var wall2_starts_on: bool = false
@export var wall3_starts_on: bool = false

@export_range(0.05, 30.0, 0.05) var wall1_toggle_delay: float = 1.0
@export_range(0.05, 30.0, 0.05) var wall2_toggle_delay: float = 1.0
@export_range(0.05, 30.0, 0.05) var wall3_toggle_delay: float = 1.0

func _ready() -> void:
	laser_wall.active = wall1_starts_on
	laser_wall_2.active = wall2_starts_on
	laser_wall_3.active = wall3_starts_on

	_toggle_wall_loop(laser_wall, wall1_toggle_delay)
	_toggle_wall_loop(laser_wall_2, wall2_toggle_delay)
	_toggle_wall_loop(laser_wall_3, wall3_toggle_delay)


func _toggle_wall_loop(wall: LaserWall, delay_seconds: float) -> void:
	while true:
		await get_tree().create_timer(delay_seconds).timeout
		wall.active = not wall.active
