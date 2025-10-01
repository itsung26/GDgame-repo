@tool
class_name hudGui extends Control
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
@onready var crosshair_right: Line2D = $CrosshairContainer/CrosshairRIGHT
@onready var crosshair_left: Line2D = $CrosshairContainer/CrosshairLEFT
@onready var crosshair_up: Line2D = $CrosshairContainer/CrosshairUP
@onready var crosshair_down: Line2D = $CrosshairContainer/CrosshairDOWN

@export_category("Crosshair Properties")
## Determines the width of the crosshair beams. This should probably remain constant throughout runtime, but is capable of changing.
@export var crosshair_width := 1.0
## Determines the color of the crosshair beams.
@export var crosshair_albedo := Color.WHITE
## Determines the distance of the beams from the center of the crosshair.
@export var crosshair_spread := 1.0
## Determines the length of the crosshair beams.
@export var crosshair_length := 5.0

var pistol
var pistol_on_overclock = false
var crosshair_lines := []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint():
		print("in editor")
		crosshair_lines = [crosshair_left, crosshair_right, crosshair_down, crosshair_up]
	else:
		pistol = player.get_node("Pivot/Camera3D/Guns/Pistol")
		crosshair_lines = [crosshair_left, crosshair_right, crosshair_down, crosshair_up]
	
func barChargeSetReady():
	pistol.isCharged = true
	
func barChargeSetNotReady():
	pistol.isCharged = false
	
func startBarFill():
	animation_player.play("bar_charge_fill")

func setOnState():
	player.zoomOut()
	pistol_on_overclock = true

func setOffState():
	player.zoomIn()
	pistol_on_overclock = false

# updates the ammo counter based on the weapon's ammo and name. To be called every frame.
func updateAmmoCounter():
	if player.weapon_state == player.weapon_states.PISTOL:
		ammo_counter.text = str(player.PISTOL_AMMO) + "/" + str(player.PISTOL_MAGSIZE)
	elif player.weapon_state == player.weapon_states.BLL:
		ammo_counter.text = str(player.BLL_AMMO) + "/" + str(player.BLL_MAGSIZE)

# updates the crosshair based on editor set properties
func updateCrosshair(width:float=crosshair_width, color:Color=crosshair_albedo, spread:float=crosshair_spread, length:float=crosshair_length):
	for crosshairline:Line2D in crosshair_lines:
		# update width
		crosshairline.width = width
		# update color
		crosshairline.default_color = color
		# update the positions from center
		if crosshairline == crosshair_right:
			# set the first point's position
			crosshair_right.set_point_position(0, Vector2(spread, 0))
			# set the second point's position
			crosshair_right.set_point_position(1, Vector2(spread + length, 0))
		elif crosshairline == crosshair_left:
			# set the first point's position
			crosshair_left.set_point_position(0, Vector2(-spread, 0))
			# set the second point's position
			crosshair_left.set_point_position(1, Vector2(-spread - length, 0))
		elif crosshairline == crosshair_up:
			# set the first point's position
			crosshair_up.set_point_position(0, Vector2(0, -spread))
			# set the second point's position
			crosshair_up.set_point_position(1, Vector2(0, -spread - length))
		elif crosshairline == crosshair_down:
			# set the first point's position
			crosshair_down.set_point_position(0, Vector2(0, spread))
			# set the second point's position
			crosshair_down.set_point_position(1, Vector2(0, spread + length))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	if Engine.is_editor_hint():
		updateCrosshair()
	else:
		updateAmmoCounter()
		updateCrosshair()
			
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
		
