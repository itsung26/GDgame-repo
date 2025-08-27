extends Node3D
@onready var bll_animator: AnimationPlayer = $"../../../../BLLAnimator"
@onready var player: CharacterBody3D = $"../../../.."
@onready var fire_ready_light_green: MeshInstance3D = $SightPart/FireReadyLightGREEN
@onready var fire_ready_light_red: MeshInstance3D = $SightPart/FireReadyLightRED

var can_play_anims : bool = true

func BLLFire():
	print("kaboom")
	Global.BLL_ammo -= 1
	bll_animator.play("Black Hole Launcher/BLL_cooldown")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func denyAnims():
	can_play_anims =false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Global.BLL_ammo > 0:
		if not bll_animator.is_playing():
			fire_ready_light_green.visible = true
			fire_ready_light_red.visible = false
	
	elif Global.BLL_ammo == 0:
		fire_ready_light_red.visible = true
		fire_ready_light_green.visible = false
		if not bll_animator.is_playing() and can_play_anims:
			bll_animator.play("Black Hole Launcher/BLL_put_down")
