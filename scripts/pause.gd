class_name pauseMenu extends Control
@onready var resume: Button = $CenterButtons/Resume
@onready var options_menu: Control = $OptionsMenu
@onready var center_buttons: Control = $CenterButtons
@onready var shader_toggle: CheckButton = $OptionsMenu/ShaderToggle
@onready var play: MeshInstance3D = $"../world_parts/Play"
@onready var quit: MeshInstance3D = $"../world_parts/Quit"
@onready var quit_animator: AnimationPlayer = $"../quit_animator"
@onready var quit_confirm: MeshInstance3D = $"../world_parts/wall_quit_confirm/quit_confirm"
@onready var quit_cancel: MeshInstance3D = $"../world_parts/wall_quit_confirm/quit_cancel"
@onready var quit_confirm_capsule_animator: AnimationPlayer = $"../quit_confirm_capsule_animator"
@onready var player: CharacterBody3D = get_tree().current_scene.find_child("Player")
@onready var free_slide_toggle: CheckButton = $OptionsMenu/HBoxContainer/GameplayBox/FreeSlideToggleHolder/FreeSlideToggle

# objects
var hud
var pixel_shader


# variables
var pixel_shader_enabled := false
var mouse_in_quit_button
var mouse_in_play_button
var mouse_in_confirm_quit_button
var mouse_in_cancel_quit_button

# state machine
enum pause_states {UNPAUSED,MAIN,OPTIONS}
var pause_state := pause_states.UNPAUSED:
	set = set_state

@export_category("Mouse Behavior")
@export var lock_mouse_on_exit := true
@export var show_mouse_on_enter := true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	options_menu.visible = false
	center_buttons.visible = false
	hud = get_node("../HUD")
	pixel_shader = get_node("../PixelShader")
	# if no pixel shader is in the scene, remove the button
	if not pixel_shader:
		$OptionsMenu/ShaderToggle.visible = false

func set_state(new_state:int):
	var previous_state = pause_state
	pause_state = new_state

	# when state is switched to------------------------------------------------------------
	if new_state == pause_states.MAIN:
		visible = true
		center_buttons.visible = true
		hud.visible = false
		get_tree().paused = true
		if show_mouse_on_enter:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	elif new_state == pause_states.OPTIONS:
		options_menu.visible = true
	
	elif new_state == pause_states.UNPAUSED:
		hud.visible = true
		get_tree().paused = false
		if lock_mouse_on_exit:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
		
	# when state is switched from ------------------------------------------------------------
	if previous_state == pause_states.MAIN:
		center_buttons.visible = false
	
	elif previous_state == pause_states.OPTIONS:
		options_menu.visible = false
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(float) -> void:
	shaderOverlayLogic()
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouse and Input.is_action_just_pressed("fire") and mouse_in_quit_button:
		quit_animator.play("quit_confirm")
	elif event is InputEventMouse and Input.is_action_just_pressed("fire") and mouse_in_confirm_quit_button:
		get_tree().quit()
	elif event is InputEventMouse and Input.is_action_just_pressed("fire") and mouse_in_cancel_quit_button:
		quit_animator.play_backwards("quit_confirm")
		
			
	elif event is InputEventKey:
		# checks for pause input
		if Input.is_action_just_pressed("pause"):
			if pause_state == pause_states.UNPAUSED:
				pause_state = pause_states.MAIN
			
			elif pause_state == pause_states.MAIN:
				pause_state = pause_states.UNPAUSED
			
			elif pause_state == pause_states.OPTIONS:
				pause_state = pause_states.UNPAUSED


func shaderOverlayLogic():
	# checks for the shader's prescence in the scene
	if pixel_shader:
		if pixel_shader_enabled:
			pixel_shader.visible = true
		else:
			pixel_shader.visible = false

# resumes the game
func _on_resume_pressed() -> void:
	pause_state = pause_states.MAIN
	pause_state = pause_states.UNPAUSED

# opens options menu
func _on_options_pressed() -> void:
	pause_state = pause_states.OPTIONS

 # quits
func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_back_pressed() -> void:
	pause_state = pause_states.MAIN


func _on_shader_toggle_toggled(toggled_on: bool) -> void:
	pixel_shader_enabled = toggled_on

# when mouse enters quit button
func _on_area_3d_mouse_entered() -> void:
	mouse_in_quit_button = true
	quit.get_active_material(0).albedo_color = Color.RED

# when mouse leaves quit button
func _on_area_3d_mouse_exited() -> void:
	mouse_in_quit_button = false
	quit.get_active_material(0).albedo_color = Color.WHITE

# when mouse enters quit confrim button
func _on_mouse_enter_quit_confirm() -> void:
	mouse_in_confirm_quit_button = true
	quit_confirm.get_active_material(0).albedo_color = Color.RED
	quit_confirm_capsule_animator.play("shake_infinitely")

# when mouse leaves quit confrim button
func _on_mouse_leave_quit_confirm() -> void:
	mouse_in_confirm_quit_button = false
	quit_confirm.get_active_material(0).albedo_color = Color.WHITE
	quit_confirm_capsule_animator.stop()

# on mouse enter quit cancel
func _on_quit_cancel_mouse_entered() -> void:
	mouse_in_cancel_quit_button = true
	quit_cancel.get_active_material(0).albedo_color = Color.RED
	quit_confirm_capsule_animator.play("nod_infinitely")

# on mouse leave quit cancel
func _on_quit_cancel_mouse_exited() -> void:
	mouse_in_cancel_quit_button = false
	quit_cancel.get_active_material(0).albedo_color = Color.WHITE
	quit_confirm_capsule_animator.stop()

func _on_free_slide_toggle_toggled(toggled_on: bool) -> void:
	player.free_slide_enabled = toggled_on
	print(player.free_slide_enabled)
