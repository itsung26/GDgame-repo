class_name HudGui extends Control
@onready var ammo_counter: Label = %ammoCounter
@onready var anim_debug: Label = %AnimDebug
@onready var fps_counter: Label = %fpsCounter
@onready var hooked_target: Label = %HookedTarget
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var progress_bar: ProgressBar = $OverclockBar/ProgressBar
@onready var current_weapon_special: Label = %currentWeaponSpecial
@onready var current_weapon_state: Label = %CurrentWeaponState
@onready var current_action_state: Label = %CurrentActionState
@onready var overclock_bar: Control = $OverclockBar
@onready var key_indicator_2: AnimatedSprite2D = $pistolPreviewIcon/KeyIndicator2
@onready var current_look_dir: Label = %CurrentLookDir
@onready var pivot: Node3D = $"../../Pivot"
var current_frames_per_second = "null"
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
@onready var health_bar: ProgressBar = get_tree().current_scene.find_child("HealthBar")
@onready var black_hole_gun_outline: TextureRect = $"BottomLeftArea/AmmoPanel/SubViewport/BGpanel/WeaponOutlines/Black hole gun outline"
@onready var pistol_outline: TextureRect = $"BottomLeftArea/AmmoPanel/SubViewport/BGpanel/WeaponOutlines/Pistol outline"
@onready var hand_outline: TextureRect = $"BottomLeftArea/AmmoPanel/SubViewport/BGpanel/WeaponOutlines/Hand outline"
@onready var arm_panel: Panel = $BottomLeftArea/AmmoPanel/SubViewport/ArmPanel
@onready var arm_panel_2: Panel = $BottomLeftArea/AmmoPanel/SubViewport/ArmPanel2
@export var player:Player
@onready var debug_container: VBoxContainer = $DebugContainer
@onready var grapple_arm: GrappleArm = $"../../Pivot/Camera3D/GrappleArm"
@onready var stamina_bar: StaminaBar = $BottomLeftArea/AmmoPanel/SubViewport/BGpanel/StaminaBar

@export_category("Crosshair Properties")
## Determines the width of the crosshair beams. This should probably remain constant throughout runtime, but is capable of changing.
@export var crosshair_width := 1.0
## Determines the color of the crosshair beams.
@export var crosshair_albedo := Color.WHITE
## Determines the distance of the beams from the center of the crosshair.
@export var crosshair_spread := 1.0
## Determines the length of the crosshair beams.
@export var crosshair_length := 5.0

@export_category("UI visual properties")
@export var debug_panel_enabled:bool = true
@export var healthbar_smooth_react_enabled:bool = true
## The speed at which the healthbar fills and drains in reaction to the player being damaged
@export var healthbar_react_speed := 1.0
@export var staminabar_smooth_react_enabled:bool = true
## The speed at which the healthbar fills and drains in reaction to the player being damaged
@export var staminabar_react_speed := 1.0

var pistol_on_overclock = false
var crosshair_lines := []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	# ready debug panel
	if debug_panel_enabled:
		debug_container.visible = true
	else:
		debug_container.visible = false
	crosshair_lines = [crosshair_left, crosshair_right, crosshair_down, crosshair_up]
	
	# ready stamina
	stamina_bar.max_value = player.STAMINA
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	if Engine.is_editor_hint():
		updateCrosshair()
	else:
		updateAmmoCounter()
		updateCrosshair()
		updateHealthBar(delta)
		updateStaminaBar(delta)
			
		# get engine fps
		current_frames_per_second = Engine.get_frames_per_second()
		fps_counter.text = "FPS: " + str(current_frames_per_second)
		
		# fps counter
		if current_frames_per_second >= 30:
			fps_counter.add_theme_color_override("font_color", Color.GREEN)
		else:
			fps_counter.add_theme_color_override("font_color", Color.RED)
			
#region Debug Text
		# set debug text-------------------------------------------------------------------------------
		current_action_state.text = "Current action state: " + player.action_states.keys()[player.action_state]
		hooked_target.text = "grapple target: " + str(grapple_arm.hooked_target)
		current_weapon_state.text = "Current weapon state: " + player.weapon_state.to_string()
		current_look_dir.text = "lookDir: " + str(pivot.rotation_degrees + player.rotation_degrees)
		current_player_pos.text = "GPos: " + str(player.global_position)
		current_player_health.text = "Player health: " + str(player.HEALTH)
		current_player_state.text = "Player/Phys state: " + player.player_states.keys()[player.player_state]
		%CurrentVelocity.text = "Net vector: " + str(player.velocity)
		%CurrentMagnitude.text = "Net vector magnitude: " + str(roundi(player.velocity.length()))
		%CurrentParryTarget.text = "parry target: " + str(player.parry_target)
		%CurrentCombatState.text = "In Combat: " + str(player.in_combat)
		%HookActive.text = "Hook active: " + str(player.grapple_arm.hook_active)
		# ----------------------------------------------------------------------------------------------
#endregion

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("debug func 2"):
		if debug_container.visible == true:
			debug_container.visible = false
		elif debug_container.visible == false:
			debug_container.visible = true

## Recieves state machine state change calls from player through a signal
func _on_player_entered_arm_state(new_arm_state: Player.arm_states, previous_arm_state: Player.arm_states) -> void:
	if new_arm_state == Player.arm_states.GRAPPLEARM:
		arm_panel.visible = true
	if previous_arm_state == Player.arm_states.GRAPPLEARM:
		arm_panel.visible = false
	
	if new_arm_state == Player.arm_states.PARRYARM:
		arm_panel_2.visible = true
	if previous_arm_state == Player.arm_states.PARRYARM:
		arm_panel_2.visible = false


# updates the ammo counter based on the weapon's ammo and name. To be called every frame.
func updateAmmoCounter():
	pass

# updates the crosshair based on editor set properties
func updateCrosshair(width:float=crosshair_width, color:Color=crosshair_albedo, spread:float=crosshair_spread, length:float=crosshair_length):
	for crosshairline:Line2D in crosshair_lines:
		if crosshairline:
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

# updates the healthbar
func updateHealthBar(delta):
	if healthbar_smooth_react_enabled:
		health_bar.value = lerp(health_bar.value, player.HEALTH, healthbar_react_speed * delta)
	else:
		health_bar.value = player.HEALTH

# updates stamina bar
func updateStaminaBar(delta):
	if staminabar_smooth_react_enabled:
		stamina_bar.progress = lerp(stamina_bar.progress, player.STAMINA, staminabar_react_speed * delta)
	else: stamina_bar.progress = player.STAMINA
