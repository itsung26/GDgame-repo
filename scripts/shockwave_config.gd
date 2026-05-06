class_name ShockwaveConfig
extends Resource

@export var beginning_size:float = 1.0
@export var ending_size:float = 10.0
@export var expand_speed:float = 1.0
@export var damage:float = 1.0
@export var ring_color:Color = Color(1.0, 1.0, 1.0, 1.0)
## Must have a domain of [0, 1]. Range must be [0, 1].
@export var alpha_curve:Curve
