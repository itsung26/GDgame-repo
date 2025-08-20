extends Control
@onready var ammo_counter: Label = %ammoCounter
@onready var anim_debug: Label = %AnimDebug
@onready var camera_look_debug: Label = %CameraLookDebug
@onready var fps_counter: Label = %fpsCounter
@onready var body_hit_debug: Label = %BodyHitDebug
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var progress_bar: ProgressBar = $ProgressBar


var animation_playing_text = "null"
var camera_looking_at_text = "null"
var current_frames_per_second = "null"
var body_hit = "null"
var bar_isfull = false

signal pistol_special_ready(readystate)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	
func barChargeReady():
	bar_isfull = true
	
func barChargeNotReady():
	bar_isfull = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	current_frames_per_second = Engine.get_frames_per_second()
	fps_counter.text = "FPS: " + str(current_frames_per_second)
	if current_frames_per_second >= 30:
		fps_counter.add_theme_color_override("font_color", Color.GREEN)
	else:
		fps_counter.add_theme_color_override("font_color", Color.RED)
		
	# set the text to make it change
	anim_debug.text = animation_playing_text
	camera_look_debug.text = camera_looking_at_text
	body_hit_debug.text = body_hit
	
	# emit the bar status every frame
	pistol_special_ready.emit(bar_isfull)
	
	if progress_bar.value < 100:
		Global.pistol_isCharged = false
		animation_player.play("bar_charge_fill")
	else:
		Global.pistol_isCharged = true



# show ammo count
func _on_player_relay_blaster_ammo(amount: Variant) -> void:
	ammo_counter.text = str(amount) + "/50"

# show currently playing anim
func _on_player_relay_current_anim(anim: Variant) -> void:
	animation_playing_text = "current anim: " + anim

# show camera look direction
func _on_player_camera_look_dir(looking_at: Variant) -> void:
	camera_looking_at_text = "camera.basis: " + str(looking_at)


func _on_player_relay_body_hit(body: Variant) -> void:
	body_hit = "last body hit: " + str(body)


func _on_player_relay_bar_lower() -> void:
	animation_player.play("bar_charge_empty")
