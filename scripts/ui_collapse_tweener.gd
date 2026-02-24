class_name UICollapseTweener
extends Control

## UI animator capable of collapse and expand transitions.
## Uses move_toward and delta time instead of tweens.

enum InitialState {
	EXPANDED,
	COLLAPSED
}

signal finished_transition

@export var initial_state: InitialState = InitialState.EXPANDED
@export var vertical_collapse_time: float = 0.25
@export var vertical_expand_time: float = 0.25
@export var nodes_to_hide: Array[Control]

@export var _y_size_collapsed: float = 0.0
@export var _y_size_expanded: float = 200.0

var animating: bool = false
var collapsed: bool = false
var _initial_pos: Vector2 = Vector2.ZERO
var _expanded_pos: Vector2 = Vector2.ZERO

var _target_size: Vector2 = Vector2.ZERO
var _target_position: Vector2 = Vector2.ZERO
var _anim_duration: float = 0.0
var _anim_elapsed: float = 0.0
var _anim_collapsing: bool = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_READY:
		process_mode = Node.PROCESS_MODE_ALWAYS
		_expanded_pos = position
		_initial_pos = _expanded_pos + Vector2(0.0, _y_size_expanded / 2.0)
		if initial_state == InitialState.COLLAPSED:
			instantCollapseVertical()
		elif initial_state == InitialState.EXPANDED:
			instantExpandVertical()


func _process(delta: float) -> void:
	if not animating:
		return
	var remaining: float = _anim_duration - _anim_elapsed
	if remaining <= 0.0 or delta >= remaining:
		size = _target_size
		position = _target_position
		animating = false
		_anim_elapsed = 0.0
		if _anim_collapsing:
			collapsed = true
		else:
			collapsed = false
			_show_nodes_to_hide()
		finished_transition.emit()
		return
	var step_size: float = size.distance_to(_target_size) * (delta / remaining)
	var step_pos: float = position.distance_to(_target_position) * (delta / remaining)
	size = size.move_toward(_target_size, step_size)
	position = position.move_toward(_target_position, step_pos)
	# Keep vertical center fixed at _initial_pos.y so the item stays centered while animating
	position.y = _initial_pos.y - size.y / 2.0
	_anim_elapsed += delta


#func _apply_initial_state_collapsed() -> void:
	#_initial_pos = position
	#size = Vector2(size.x, _y_size_collapsed)
	#position = position + Vector2(0, _y_size_expanded / 2.0)
	#collapsed = true
	#for node in nodes_to_hide:
		#node.visible = false


## Executes a vertical collapse. No-op if already collapsed or if a collapse/expand animation is in progress.
func collapseVertical():
	if collapsed and not animating:
		instantExpandVertical()
	if animating:
		instantExpandVertical()
	animating = true
	_anim_collapsing = true
	for node in nodes_to_hide:
		node.visible = false
	_target_size = Vector2(size.x, _y_size_collapsed)
	_target_position = _initial_pos
	_anim_duration = vertical_collapse_time
	_anim_elapsed = 0.0


## Executes a vertical expansion. No-op if already expanded or if a collapse/expand animation is in progress.
func expandVertical() -> void:
	if not collapsed and not animating:
		instantCollapseVertical()
	if animating:
		instantCollapseVertical()
	animating = true
	_anim_collapsing = false
	for node in nodes_to_hide:
		node.visible = false
	_target_size = Vector2(size.x, _y_size_expanded)
	_target_position = _expanded_pos
	_anim_duration = vertical_expand_time
	_anim_elapsed = 0.0


func instantCollapseVertical() -> void:
	_hide_nodes_to_hide()
	size.y = _y_size_collapsed
	position = _initial_pos
	collapsed = true

	
func instantExpandVertical() -> void:
	_show_nodes_to_hide()
	size.y = _y_size_expanded
	position = _expanded_pos
	collapsed = false

	
func _show_nodes_to_hide() -> void:
	for node in nodes_to_hide:
		node.visible = true


func _hide_nodes_to_hide() -> void:
	for node in nodes_to_hide:
		node.visible = false
