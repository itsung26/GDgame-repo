class_name UICollapseTweener
extends Control

## UI animator capable of collapse and expand transitions.

signal finished_transition

@export var vertical_collapse_time:float = 0.25
@export var vertical_expand_time:float = 0.25
@export var nodes_to_hide:Array[Control]

var animating:bool = false
var collapsed:bool = false
var previous_size:Vector2 = Vector2.ZERO
var previous_pos:Vector2 =  Vector2.ZERO

## Executes a vertical collapse. Cannot collapse if already collapsed or currently tweening.
func collapseVertical():
	if animating or collapsed:
		return
	animating = true
	for node in nodes_to_hide:
		node.visible = false
	previous_pos = position
	previous_size = size
	# Move down by half height so the center stays fixed
	var collapsed_pos := position + Vector2(0, size.y / 2.0)
	var ui_tweener := create_tween().set_parallel(true)
	_make_tween_unscaled(ui_tweener)
	ui_tweener.tween_property(self, "size", Vector2(size.x, 0.0), vertical_collapse_time)
	ui_tweener.tween_property(self, "position", collapsed_pos, vertical_collapse_time)
	ui_tweener.tween_callback(func() -> void: animating = false)
	ui_tweener.tween_callback(func() -> void: collapsed = true)
	ui_tweener.tween_callback(finished_transition.emit)

## Executes a vertical expansion. Cannot expand if already expanded or currently tweening.
func expandVertical():
	if animating or not collapsed:
		return
	animating = true
	for node in nodes_to_hide:
		node.visible = false
	var ui_tweener := create_tween().set_parallel(true)
	_make_tween_unscaled(ui_tweener)
	ui_tweener.tween_property(self, "size", Vector2(size.x, previous_size.y), vertical_expand_time)
	ui_tweener.tween_property(self, "position", previous_pos, vertical_expand_time)
	ui_tweener.tween_callback(func() -> void: animating = false)
	ui_tweener.tween_callback(func() -> void: collapsed = false)
	ui_tweener.tween_callback(_show_nodes_to_hide)
	ui_tweener.tween_callback(finished_transition.emit)

## Makes the tween run at real-time speed regardless of Engine.time_scale.
## Uses set_ignore_time_scale (Godot 4.3+) or compensates via speed_scale on older versions.
func _make_tween_unscaled(tween: Tween) -> void:
	if tween.has_method("set_ignore_time_scale"):
		tween.set_ignore_time_scale(true)
	else:
		var ts: float = max(Engine.time_scale, 0.001)
		tween.set_speed_scale(1.0 / ts)

func _show_nodes_to_hide() -> void:
	for node in nodes_to_hide:
		node.visible = true
