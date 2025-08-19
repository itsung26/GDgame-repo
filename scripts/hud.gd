extends Control
@onready var ammo_counter: Label = %ammoCounter
@onready var debug: Label = %debug


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass # change the text based on blaster.gd's ammo variable


func _on_player_relay_blaster_ammo(amount: Variant) -> void:
	ammo_counter.text = str(amount) + "/50"


func _on_player_relay_current_anim(anim: Variant) -> void:
	debug.text = "current anim: " + anim
