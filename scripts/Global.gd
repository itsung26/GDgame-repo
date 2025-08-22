extends Node

'''
pistol variables===================================================================================
'''
# maybe use a dictionary instead?

const pistol_special_property = "Overclock"

var blaster_ammo = 0
var is_pistol_charged = false
var pistol_DAMAGE = 5
var pistol_MAGSIZE = 50 
var pistol_activate_special = false
var pistol_special_state = false

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
