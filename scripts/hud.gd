extends Control
@onready var ammo_counter: Label = %ammoCounter
@onready var anim_debug: Label = %AnimDebug
@onready var fps_counter: Label = %fpsCounter
@onready var body_hit_debug: Label = %BodyHitDebug
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var progress_bar: ProgressBar = $OverclockBar/ProgressBar
@onready var current_weapon_special: Label = %currentWeaponSpecial
@onready var current_weapon_state: Label = %CurrentWeaponState
@onready var current_action_state: Label = %CurrentActionState
@onready var overclock_bar: Control = $OverclockBar
@onready var key_indicator_2: AnimatedSprite2D = $pistolPreviewIcon/KeyIndicator2
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
@onready var current_player_state: Label = %CurrentPlayerState

var pistol

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pistol = player.get_node("Pivot/Camera3D/Guns/Pistol")
	
func barChargeSetReady():
	pistol.isCharged = true
	
func barChargeSetNotReady():
	pistol.isCharged = false
	
func startBarFill():
	animation_player.play("bar_charge_fill")

func setOnState():
	player.zoomOut()

func setOffState():
	player.zoomIn()
	
func updateAmmoCounter():
	if player.weapon_state == player.weapon_states.PISTOL:
		ammo_counter.text = str(player.PISTOL_AMMO) + "/" + str(player.PISTOL_MAGSIZE)
	elif player.weapon_state == player.weapon_states.BLL:
		ammo_counter.text = str(player.BLL_AMMO) + "/" + str(player.BLL_MAGSIZE)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	
	updateAmmoCounter()	
		
	# get engine fps
	current_frames_per_second = Engine.get_frames_per_second()
	fps_counter.text = "FPS: " + str(current_frames_per_second)
	
	# fps counter
	if current_frames_per_second >= 30:
		fps_counter.add_theme_color_override("font_color", Color.GREEN)
	else:
		fps_counter.add_theme_color_override("font_color", Color.RED)
		
	# set debug text-------------------------------------------------------------------------------
	current_action_state.text = "Current action state: " + player.current_action_string_name
	body_hit_debug.text = "last object hit: " + str(Global.body_hit)
	current_weapon_state.text = "Current weapon state: " + player.current_weapon_string_name
	current_look_dir.text = "Currently looking in direction: " + str(pivot.rotation_degrees + player.rotation_degrees)
	current_player_pos.text = "Player Global Position: " + str(player.global_position)
	current_player_health.text = "Player health: " + str(player.HEALTH)
	current_player_state.text = "Current player state: " + player.current_player_string_name
	%CurrentVelocity.text = "Player Velocity Vector: " + str(player.velocity)
	%CurrentMagnitude.text = "Current Velocity Magnitude: " + str(roundi(player.velocity.length()))
	%CurrentMagnitudeXZ.text = "Current player velocity magnitude (XZ plane): " + str(roundi(Vector2(player.velocity.x, player.velocity.z).length()))
	# ----------------------------------------------------------------------------------------------
	
