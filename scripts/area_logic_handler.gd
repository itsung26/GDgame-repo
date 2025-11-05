## Handles area3d logic for this level
extends Node

@onready var tablet_text: MeshInstance3D = $"../the cold winds map/cold_winds/startingZone/Sci-fi Tablet/tabletText"

func _on_tablet_interact_body_entered(body: Player) -> void:
	tablet_text.visible = true


func _on_tablet_interact_body_exited(body: Player) -> void:
	tablet_text.visible = false
