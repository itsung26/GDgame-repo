class_name FreeCamera
extends Camera3D


## Matches the 3D editor fly camera: hold right mouse to look, WASD to move, Q/E down/up, Shift faster.
@export var move_speed: float = 5.0
@export var fast_multiplier: float = 3.0
@export var mouse_sensitivity: float = 0.003
@export var max_pitch_rad: float = deg_to_rad(89.0)


var looking: bool = false
var mouse_mode_before_look: Input.MouseMode = Input.MOUSE_MODE_VISIBLE
var yaw: float = 0.0
var pitch: float = 0.0


func _ready() -> void:
	yaw = rotation.y
	pitch = rotation.x



func _input(event: InputEvent) -> void:
	if not is_current():
		return
	if event.is_action_pressed("pause") and looking:
		looking = false
		Input.mouse_mode = mouse_mode_before_look
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				mouse_mode_before_look = Input.get_mouse_mode()
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				looking = true
			else:
				looking = false
				Input.mouse_mode = mouse_mode_before_look
	elif event is InputEventMouseMotion and looking:
		var mm: InputEventMouseMotion = event
		yaw -= mm.relative.x * mouse_sensitivity
		pitch = clampf(
			pitch - mm.relative.y * mouse_sensitivity,
			-max_pitch_rad,
			max_pitch_rad
		)
		rotation = Vector3(pitch, yaw, 0.0)



func _process(delta: float) -> void:
	if not is_current():
		return
	# Third/fourth args are negative_y / positive_y: "back" then "forward" so W maps to +planar.y.
	var planar: Vector2 = Input.get_vector("left", "right", "back", "forward")
	var vertical: float = 0.0
	if Input.is_physical_key_pressed(KEY_SPACE):
		vertical += 1.0
	if Input.is_physical_key_pressed(KEY_CTRL):
		vertical -= 1.0
	var speed: float = move_speed
	if Input.is_physical_key_pressed(KEY_SHIFT):
		speed *= fast_multiplier
	var basis: Basis = global_transform.basis
	var forward: Vector3 = -basis.z
	var right: Vector3 = basis.x
	var move: Vector3 = right * planar.x + forward * planar.y + Vector3.UP * vertical
	if move.length_squared() > 0.0001:
		move = move.normalized() * speed * delta
		global_position += move
