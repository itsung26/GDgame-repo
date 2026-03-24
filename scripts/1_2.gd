extends Level

@onready var world_environment: WorldEnvironment = $WorldEnvironment

@export var initial_fog_density:float = 0.0
@export var full_fog_density:float = 0.01
@export var fog_density_speed:float = 1.0

enum fog_states {INCREASING, DECREASING, NONE}

var fog_state: fog_states = fog_states.NONE:
	set = setFogState


func setFogState(new_fog_state:fog_states) -> void:
	fog_state = new_fog_state


func _onLevelReady() -> void:
	var enviroment:Environment = world_environment.environment
	enviroment.fog_density = initial_fog_density


func _onLevelTick(_delta: float) -> void:
	if fog_state == fog_states.INCREASING:
		var enviroment:Environment = world_environment.environment
		enviroment.fog_density = lerpf(enviroment.fog_density, full_fog_density, fog_density_speed * _delta)
	elif fog_state == fog_states.DECREASING:
		var enviroment:Environment = world_environment.environment
		enviroment.fog_density = lerpf(enviroment.fog_density, initial_fog_density, fog_density_speed * _delta)


func _on_fog_changer_body_entered(body: Node3D) -> void:
	if body is Player:
		setFogState(fog_states.INCREASING)
		$AreaCollections/FogChanger/CollisionShape3D.disabled = true
