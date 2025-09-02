extends Node

var current_special_property
var current_MAGSIZE
var current_DAMAGE
var current_AMMO
var pivot_look_basis


# note: magsize should always be the same as ammo.
# this is intended to allow for infinite ammo as (most) guns are intended to fire forever

'''
pistol variables===================================================================================
pistol special: Overclock- increases player speed, damage, jump, and reload speed for a short amount of time.
Runs on a cooldown.
'''
# maybe use a dictionary instead?
# no.

const pistol_special_property = "Overclock"

var blaster_ammo = 50
var is_pistol_charged = false
var pistol_DAMAGE = 5
var pistol_MAGSIZE = 50 
var pistol_activate_special = false
var pistol_special_state = false

'''
shotgun variables===================================================================================
shotgun special: Dragon's Breath- Empty both barrels in a fiery explosion with a large AoE that sets
enemies on fire, dealing damage over time.
Runs on a cooldown. 
'''

const shotgun_special_property = "Dragon's Breath"

var shotgun_ammo = 2
var is_shotgun_charged = true
# total damage of the shotgun if all pellets hit should be high
# individual pellet damage should be low
# enemy hp is 100, so total dmg should be >= 100 if all pellets hit
# twelve pellets
# total damage = 8 * 12 = 60
var shotgun_DAMAGE = 8
var shotgun_MAGSIZE = 2
var shotgun_activate_special = false
var shotgun_special_state= false

'''
melee variables===================================================================================
melee special: undecided.
Runs on a cooldown. 
'''

const melee_special_property = "n/a"

var melee_ammo = 999999999
var melee_DAMAGE = 5
var melee_MAGSIZE =  999999999
var melee = false
var melee_special_state = false

'''
Black Hole Launcher variables===================================================================================
special: N/A
Runs on a cooldown. 
'''

const BLL_special_property = "n/a"

var BLL_times_fired : int = 0
var BLL_ammo = 3
var BLL_DAMAGE = 500
var BLL_MAGSIZE =  3
var BLL_special_state = false

'''
debug variables for the custom debug window===============================================================
'''
var body_hit = "null"
var anim_playing = "null"
var current_weapon = "pistol"
var current_fireType = "RAYCAST_PISTOL"

'''
current variables===================================================================================
i don't want to deal with dictionaries
these variables update every frame to the current type of element that corresponds to the weapon you have
EX: current_weapon is "shotgun", current_magsize updates to shotgun_MAGSIZE
this is inefficient, but eliminates the need for a huge dictionary with properties
'''
func _process(_float) -> void:
	
	if current_weapon == "pistol":
		current_DAMAGE = pistol_DAMAGE
		current_MAGSIZE = pistol_MAGSIZE
		current_special_property = pistol_special_property
		current_AMMO = blaster_ammo
	
	elif current_weapon == "shotgun":
		current_DAMAGE = shotgun_DAMAGE
		current_MAGSIZE = shotgun_MAGSIZE
		current_special_property = shotgun_special_property
		current_AMMO = shotgun_ammo
		
	elif current_weapon == "melee":
		current_DAMAGE = melee_DAMAGE
		current_MAGSIZE = melee_MAGSIZE
		current_special_property = melee_special_property
		current_AMMO = melee_ammo
	
	elif current_weapon == "BLL":
		current_DAMAGE = BLL_DAMAGE
		current_MAGSIZE = BLL_MAGSIZE
		current_special_property = BLL_special_property
		current_AMMO = BLL_ammo

'''
other global vars===============================================================
'''
var isPaused = false
var menuState = "notpaused"
var enableShader = false
var player_move_input_enabled = true
