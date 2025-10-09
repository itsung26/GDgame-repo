extends Node
@onready var player = get_tree().current_scene.find_child("Player")
@onready var pistol_outline: TextureRect = $"../BottomLeftArea/AmmoPanel/SubViewport/BGpanel/WeaponOutlines/Pistol outline"
@onready var hand_outline: TextureRect = $"../BottomLeftArea/AmmoPanel/SubViewport/BGpanel/WeaponOutlines/Hand outline"
@onready var black_hole_gun_outline: TextureRect = $"../BottomLeftArea/AmmoPanel/SubViewport/BGpanel/WeaponOutlines/Black hole gun outline"



# recieves signal on player weapon state change
func _on_player_entered_weapon_state(new_weapon_state: int, previous_weapon_state:int) -> void:
	# ladder for current (new) weapon
	match new_weapon_state:
		player.weapon_states.PISTOL:
			pistol_outline.visible = true
		player.weapon_states.BLL:
			black_hole_gun_outline.visible = true
		player.weapon_states.MELEE:
			hand_outline.visible = true
	
	# ladder for old weapon
	match previous_weapon_state:
		player.weapon_states.PISTOL:
			pistol_outline.visible = false
		player.weapon_states.BLL:
			black_hole_gun_outline.visible = false
		player.weapon_states.MELEE:
			hand_outline.visible = false
