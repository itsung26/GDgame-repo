extends Node

var current_special_property

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
debug variables for the custom debug window===============================================================
'''
var body_hit = "null"
var anim_playing = "null"
var current_weapon = "pistol" # valid values are: "pistol"
var current_fireType = "RAYCAST_PISTOL"

'''
other global variables needed to cross scenes===============================================================
'''
# n/a for now
