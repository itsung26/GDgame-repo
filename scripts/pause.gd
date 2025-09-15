extends Control
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

# objects
var hud
var pixel_shader


# variables
var menuState := "notpaused"
var isPaused := false
var pixel_shader_enabled := false
var mouse_in_quit_button
var mouse_in_play_button
var mouse_in_confirm_quit_button
var mouse_in_cancel_quit_button

# one time toggle signals
signal initiatePause
signal initiateUnpause

@export_category("Mouse Behavior")
@export var lock_mouse_on_exit := true
@export var show_mouse_on_enter := true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	hud = get_node("../HUD")
	pixel_shader = get_node("../PixelShader")
	
	# if no pixel shader is in the scene, remove the button
	if not pixel_shader:
		$OptionsMenu/ShaderToggle.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(float) -> void:
	
	
	shaderOverlayLogic()
	checkMenuStates()
	
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
			if not isPaused:
				initiatePause.emit()
			
			elif isPaused:
				initiateUnpause.emit()

		
func checkMenuStates():
	if menuState == "main":
		visible = true
		center_buttons.visible = true
		options_menu.visible = false
		if hud:
			hud.visible = false

	elif menuState == "options":
		options_menu.visible = true
		center_buttons.visible = false

	elif menuState == "notpaused":
		visible = false
		options_menu.visible = false
		center_buttons.visible = false
		if hud:
			hud.visible = true
func shaderOverlayLogic():
	# checks for the shader's prescence in the scene
	if pixel_shader:
		if pixel_shader_enabled:
			pixel_shader.visible = true
		else:
			pixel_shader.visible = false

# resumes the game
func _on_resume_pressed() -> void:
	initiateUnpause.emit()

# opens options menu
func _on_options_pressed() -> void:
	menuState = "options"

# quits
func _on_quit_pressed() -> void:
	menuState = "main"
	get_tree().quit()


func _on_back_pressed() -> void:
	menuState = "main"


func _on_shader_toggle_toggled(toggled_on: bool) -> void:
	pixel_shader_enabled = toggled_on

func _on_multiplater_pressed() -> void:
	menuState = "multiplayer"

func _on_initiate_pause() -> void:
	print("pausing")
	menuState = "main"
	get_tree().paused = true
	isPaused = true
	if show_mouse_on_enter:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_initiate_unpause() -> void:
	print("unpausing")
	menuState = "notpaused"
	get_tree().paused = false
	isPaused = false
	if lock_mouse_on_exit:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

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
