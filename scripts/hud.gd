extends Control
@onready var ammo_counter: Label = %ammoCounter
@onready var anim_debug: Label = %AnimDebug
@onready var camera_look_debug: Label = %CameraLookDebug


var animation_playing_text = "null"
var camera_looking_at_text = "null"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	anim_debug.text = animation_playing_text
	camera_look_debug.text = camera_looking_at_text

# show ammo count
func _on_player_relay_blaster_ammo(amount: Variant) -> void:
	ammo_counter.text = str(amount) + "/50"

# show currently playing anim
func _on_player_relay_current_anim(anim: Variant) -> void:
	animation_playing_text = "current anim: " + anim

# show camera look direction
func _on_player_camera_look_dir(looking_at: Variant) -> void:
	camera_looking_at_text = "camera.bais: " + str(looking_at)
