class_name UICollapseTweener
extends Control

## UI animator capable of collapse and expand transitions.

enum InitialState {
	EXPANDED,
	COLLAPSED
}

signal finished_transition

@export var initial_state: InitialState = InitialState.EXPANDED
@export var vertical_collapse_time: float = 0.25
@export var vertical_expand_time: float = 0.25
@export var nodes_to_hide: Array[Control]

#@export_tool_button("Expand") var a = foo
#@export_tool_button("Collapse") var b = bar

var animating: bool = false
var collapsed: bool = false
var previous_size: Vector2 = Vector2.ZERO
var previous_pos: Vector2 = Vector2.ZERO
var _current_tween: Tween


func _notification(what: int) -> void:
	if what == NOTIFICATION_READY and initial_state == InitialState.COLLAPSED:
		call_deferred("_apply_initial_state_collapsed")


func _apply_initial_state_collapsed() -> void:
	previous_pos = position
	previous_size = size
	size = Vector2(size.x, 0.0)
	position = position + Vector2(0, previous_size.y / 2.0)
	collapsed = true
	for node in nodes_to_hide:
		node.visible = false

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
	_current_tween = create_tween().set_parallel(true)
	_make_tween_unscaled(_current_tween)
	_current_tween.tween_property(self, "size", Vector2(size.x, 0.0), vertical_collapse_time)
	_current_tween.tween_property(self, "position", collapsed_pos, vertical_collapse_time)
	_current_tween.tween_callback(func() -> void: animating = false)
	_current_tween.tween_callback(func() -> void: collapsed = true)
	_current_tween.tween_callback(finished_transition.emit)


## Executes a vertical expansion. Cannot expand if already expanded.
## If already expanding, cancels the current tween and restarts expansion from collapsed state.
func expandVertical():
	if not collapsed and not animating:
		return
	if animating and collapsed:
		if _current_tween:
			_current_tween.kill()
		animating = false
		size = Vector2(previous_size.x, 0.0)
		position = previous_pos + Vector2(0, previous_size.y / 2.0)
	animating = true
	for node in nodes_to_hide:
		node.visible = false
	_current_tween = create_tween().set_parallel(true)
	_make_tween_unscaled(_current_tween)
	_current_tween.tween_property(self, "size", Vector2(size.x, previous_size.y), vertical_expand_time)
	_current_tween.tween_property(self, "position", previous_pos, vertical_expand_time)
	_current_tween.tween_callback(func() -> void: animating = false)
	_current_tween.tween_callback(func() -> void: collapsed = false)
	_current_tween.tween_callback(_show_nodes_to_hide)
	_current_tween.tween_callback(finished_transition.emit)


#func foo() -> void:
	#expandVertical()
#
#
#func bar() -> void:
	#collapseVertical()


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
