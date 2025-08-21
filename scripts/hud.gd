extends Control
@onready var ammo_counter: Label = %ammoCounter
@onready var anim_debug: Label = %AnimDebug
@onready var camera_look_debug: Label = %CameraLookDebug
@onready var fps_counter: Label = %fpsCounter
@onready var body_hit_debug: Label = %BodyHitDebug
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var progress_bar: ProgressBar = $OverclockBar/ProgressBar
@onready var current_weapon_special: Label = %currentWeaponSpecial

var current_frames_per_second = "null"

signal zoom_in_trigger
signal zoom_out_trigger

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	
func barChargeReady():
	Global.is_pistol_charged = true
	Global.pistol_activate_special = false
	
func barChargeNotReady():
	Global.is_pistol_charged = false
	
func triggerZoomIn():
	zoom_in_trigger.emit()
	
func triggerZoomOut():
	zoom_out_trigger.emit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	
	# if the bar is totally empty, begin refilling, disable special state, and put screen back to like before
	# if the bar is totally empty, disable the special state
	if progress_bar.value == 0:
		animation_player.play("bar_charge_fill")
		Global.pistol_special_state = false
		
	# get engine fps
	current_frames_per_second = Engine.get_frames_per_second()
	fps_counter.text = "FPS: " + str(current_frames_per_second)
	
	# update the ammo counter
	ammo_counter.text = str(Global.blaster_ammo) + "/" + str(Global.pistol_MAGSIZE)
	
	# fps counter
	if current_frames_per_second >= 30:
		fps_counter.add_theme_color_override("font_color", Color.GREEN)
	else:
		fps_counter.add_theme_color_override("font_color", Color.RED)
		
	# if rmb clicked, initiate barcharge empty animation
	if Global.pistol_activate_special :
		if not animation_player.is_playing():
			animation_player.play("bar_charge_empty")
		
	# set debug text-------------------------------------------------------------------------------
	anim_debug.text = "current animation: " + str(Global.anim_playing)
	camera_look_debug.text = str(Global.camera_look_dir)
	body_hit_debug.text = "last object hit: " + str(Global.body_hit)
	current_weapon_special.text = "Current weapon ability: " + Global.pistol_special_property
	# ----------------------------------------------------------------------------------------------
	
