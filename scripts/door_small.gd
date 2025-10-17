class_name Door extends Node3D
@onready var open_delay: Timer = %OpenDelay
@onready var close_delay: Timer = %CloseDelay
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var front_box: Area3D = $FrontBox
@onready var front_collider: CollisionShape3D = $FrontBox/FrontCollider

signal door_opened(door:Door)

@export_enum ("STAYOPEN", "CLOSEONEXIT", "LOCKED") var door_modes:int = 0
@export var delay_before_open:float = 1.0
@export var delay_before_close:float = 1.0
var isOpen:bool = false
var playerInFrontBox:bool = false
var previous_door_mode:int

func _ready() -> void:
	if delay_before_open == 0.0:
		delay_before_open = 0.01

	if delay_before_close == 0.0:
		delay_before_close = 0.01
		
func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_L):
		lock()
	elif Input.is_key_pressed(KEY_J):
		unlock()

# checks which mode the door is in and opens accordingly
func open():
	if door_modes == 2: # locked
		print("door locked and cannot open")
	elif door_modes == 0: # stayopen
		isOpen = true
		animation_player.play("door_open")
	elif door_modes == 1: # closeonexit
		isOpen = true
		animation_player.play("door_open")
		

# checks which mode the door is in and closes accordingly
func close():
	if door_modes == 0: # stayopen
		isOpen = false
		animation_player.play("door_close")
	elif door_modes == 1: # closeonexit
		isOpen = false
		animation_player.play("door_close")
	elif door_modes == 2: # locked
		print("door locked and cannot close")

func lock():
	previous_door_mode = door_modes
	if isOpen:
		close()
	door_modes = 2 # set to locked after closing
	
func unlock():
	door_modes = previous_door_mode
	if not isOpen:
		open()

# on front collider entered
func _on_front_box_body_entered(body: Player) -> void:
	playerInFrontBox = true
	if door_modes == 2: # locked
		front_collider.disabled = true
		playerInFrontBox = false
	else: front_collider.disabled = false
	
	if door_modes == 0: # stayopen
		if not isOpen:
			open_delay.start(delay_before_open)
	if door_modes == 1: # closeonexit
		if not isOpen:
			open_delay.start(delay_before_open)

# on front collider exited
func _on_front_box_body_exited(body: Player) -> void:
	playerInFrontBox = false
	if door_modes == 1: # closeonexit
		close_delay.start(delay_before_close)
	else: pass

# after open delay
func _on_open_delay_timeout() -> void:
	open()

# after close delay
func _on_close_delay_timeout() -> void:
	close()
