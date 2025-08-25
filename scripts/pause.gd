extends Control
@onready var resume: Button = $CenterButtons/Resume
@onready var hud: Control = $"../HUD"
@onready var options_menu: Control = $OptionsMenu
@onready var center_buttons: Control = $CenterButtons
@onready var shader_toggle: CheckButton = $OptionsMenu/ShaderToggle

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Global.isPaused:
		visible = true
	elif not Global.isPaused:
		visible = false
		
	if Global.menuState == "main":
		center_buttons.visible = true
		options_menu.visible = false
	elif Global.menuState == "options":
		options_menu.visible = true
		center_buttons.visible = false
	elif Global.menuState == "notpaused":
		options_menu.visible = false
		center_buttons.visible = false

# resumes the game
func _on_resume_pressed() -> void:
	Global.menuState = "notpaused"
	Global.isPaused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	visible = false
	get_tree().paused = false

# opens options menu
func _on_options_pressed() -> void:
	Global.menuState = "options"
	center_buttons.visible = false
	options_menu.visible = true

# quits
func _on_quit_pressed() -> void:
	Global.menuState = "main"
	get_tree().quit()


func _on_back_pressed() -> void:
	Global.menuState = "main"


func _on_shader_toggle_toggled(toggled_on: bool) -> void:
	Global.enableShader = toggled_on
