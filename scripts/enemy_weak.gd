extends CharacterBody3D

@export var health = 100
@export var gravity_enabled = true
@export var SPEED = 3
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	if health <= 0:
		animation_player.play("enemy_death")

func _physics_process(delta) -> void:
	
	# Add the gravity.
	if not is_on_floor():
		if gravity_enabled:
			velocity += get_gravity() * delta
			
	velocity.x = move_toward(velocity.x, 0, SPEED)
	velocity.z = move_toward(velocity.z, 0, SPEED)

	
	move_and_slide()
