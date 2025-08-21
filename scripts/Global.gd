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
var camera_look_dir = Vector3.ZERO
