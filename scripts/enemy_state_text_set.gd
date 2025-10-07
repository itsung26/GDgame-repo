extends MeshInstance3D
@onready var enemy_dummy: CharacterBody3D = $".."
@onready var self_mesh = self.mesh

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	self_mesh.text = str(enemy_dummy.enemy_states.keys()[enemy_dummy.enemy_state]) # {FALLING}[0], {GROUNDED}[1], etc...
