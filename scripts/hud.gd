extends Control
@onready var ammo_counter: Label = %ammoCounter
@onready var anim_debug: Label = %AnimDebug
@onready var fps_counter: Label = %fpsCounter
@onready var body_hit_debug: Label = %BodyHitDebug
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var progress_bar: ProgressBar = $OverclockBar/ProgressBar
@onready var current_weapon_special: Label = %currentWeaponSpecial
@onready var current_weapon: Label = %CurrentWeapon
@onready var fire_type_debug: Label = %FireTypeDebug
@onready var overclock_bar: Control = $OverclockBar
@onready var key_indicator_2: AnimatedSprite2D = $pistolPreviewIcon/KeyIndicator2
@onready var key_animator_2: AnimationPlayer = $KeyAnimator_2
@onready var key_animator_3: AnimationPlayer = $KeyAnimator_3
@onready var key_animator_1: AnimationPlayer = $KeyAnimator_1
@onready var key_animator_4: AnimationPlayer = $KeyAnimator_4
@onready var current_look_dir: Label = %CurrentLookDir
@onready var pivot: Node3D = $"../Player/Pivot"
var current_frames_per_second = "null"
@onready var player: CharacterBody3D = $"../Player"
@onready var black_hole_2: Sprite2D = $pistolPreviewIcon/BlackHole2
@onready var pistol_bullet_icon: Sprite2D = $AmmoContainer/pistol_bullet_icon
@onready var reload_prompt: AnimatedSprite2D = $pistolPreviewIcon/ReloadPrompt
@onready var current_player_pos: Label = %CurrentPlayerPos
@onready var current_player_health: Label = %CurrentPlayerHealth
@onready var black_hole_cooldown_icon: Control = $BlackHoleCooldownIcon
@onready var black_hole_cooldown_timer: Label = $BlackHoleCooldownIcon/BlackHoleCooldownTimer
@onready var key_animator_tab: AnimationPlayer = $KeyAnimator_TAB

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
	
func updateAmmoCounter():
	ammo_counter.text = str(Global.current_AMMO) + "/" + str(Global.current_MAGSIZE)
	
func hideIcons():
	# shows or hides ui elements based on current weapon
	if Global.current_weapon == "pistol":
		overclock_bar.visible = true
		pistol_bullet_icon.visible = true
		black_hole_2.visible = false
		reload_prompt.visible = true
	else:
		overclock_bar.visible = false
	
	if Global.current_weapon == "BLL":
		reload_prompt.visible = false
		pistol_bullet_icon.visible = false
		black_hole_2.visible = true
	
	# if the bar is totally empty, begin refilling, disable special state, and put screen back to like before
	# if the bar is totally empty, disable the special state
	if progress_bar.value == 0:
		animation_player.play("bar_charge_fill")
		Global.pistol_special_state = false
		
	# if the blackhole cooldown timer is 0 or "hide": hide the cooldown icon
	if black_hole_cooldown_timer.text == str(0.00) + "s":
		black_hole_cooldown_icon.visible = false
	elif black_hole_cooldown_timer.text == "hide":
		black_hole_cooldown_icon.visible = false
	else:
		black_hole_cooldown_icon.visible = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	
	updateAmmoCounter()
	
	hideIcons()
	
		
	# get engine fps
	current_frames_per_second = Engine.get_frames_per_second()
	fps_counter.text = "FPS: " + str(current_frames_per_second)
	
	# fps counter
	if current_frames_per_second >= 30:
		fps_counter.add_theme_color_override("font_color", Color.GREEN)
	else:
		fps_counter.add_theme_color_override("font_color", Color.RED)
		
	# if rmb clicked, initiate barcharge empty animation
	if Global.pistol_activate_special :
		if not animation_player.is_playing():
			animation_player.play("bar_charge_empty")
			
	# set the corresponding input keys animation frames to react to the current weapon
	if Global.current_weapon == "pistol":
		key_animator_2.play("key_2_set_dark")
	else:
		key_animator_2.play("key_2_set_light")
	
	if Global.current_weapon == "shotgun":
		key_animator_3.play("key_3_set_dark")
	else:
		key_animator_3.play("key_3_set_light")
		
	if Global.current_weapon == "melee":
		key_animator_1.play("key_1_set_light")
	else:
		key_animator_1.play("key_1_set_dark")
		
	if Global.current_weapon == "BLL":
		key_animator_4.play("key_4_set_light")
	else:
		key_animator_4.play("key_4_set_dark")
		
	if Input.is_action_pressed("weaponwheel"):
		key_animator_tab.play("key_tab_set_dark")
	if not Input.is_action_pressed("weaponwheel"):
		key_animator_tab.play("key_tab_set_light")
		
	# set debug text-------------------------------------------------------------------------------
	anim_debug.text = "current animation: " + str(Global.anim_playing)
	fire_type_debug.text = "Current fireType: " + str(Global.current_fireType)
	body_hit_debug.text = "last object hit: " + str(Global.body_hit)
	current_weapon_special.text = "Current weapon ability: " + Global.current_special_property
	current_weapon.text = "Current weapon: " + str(Global.current_weapon)
	current_look_dir.text = "Currently looking in direction: " + str(pivot.rotation_degrees + player.rotation_degrees)
	current_player_pos.text = "Player Pos: " + str(player.global_position)
	current_player_health.text = "Player health: " + str(player.HEALTH)
	
	# ----------------------------------------------------------------------------------------------
	
