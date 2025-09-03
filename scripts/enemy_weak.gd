extends CharacterBody3D

@export var health = 100
@export var gravity_enabled = true
@export var SPEED = 3
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var player: Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Find the player node anywhere in the scene tree
	player = get_tree().get_root().find_child("Player", true, false)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	if health <= 0:
		animation_player.play("enemy_death")
	if player:
		nav_agent.target_position = player.global_position
	if nav_agent.is_navigation_finished():
		# print("Navigation finished or no path!")
		pass
	else:
		# print("Next path position: ", nav_agent.get_next_path_position())
		pass

func _physics_process(delta) -> void:
	# Navigation movement
	if nav_agent.is_navigation_finished() == false:
		var next_pos = nav_agent.get_next_path_position()
		var direction = (next_pos - global_position).normalized()
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = 0
		velocity.z = 0
	
	
	# Add the gravity.
	if not is_on_floor():
		if gravity_enabled:
			velocity += get_gravity() * delta

	
	move_and_slide()
