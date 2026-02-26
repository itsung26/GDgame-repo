class_name UICollapseTweener
extends Control

## UI animator capable of collapse and expand transitions.
## Uses move_toward and delta time instead of tweens.

enum InitialState {
	EXPANDED,
	COLLAPSED
}

enum transitions {
	EXPAND_VERTICAL,
	COLLAPSE_VERTICAL
}

## Emitted when a collapse or expand animation finishes. [param transition] is [enum transitions].COLLAPSE_VERTICAL or [enum transitions].EXPAND_VERTICAL.
signal finished_transition(transition: transitions)

## Which state the control is in when the scene loads (expanded or collapsed).
@export var initial_state: InitialState = InitialState.EXPANDED
## Duration in seconds for the collapse animation.
@export var vertical_collapse_time: float = 0.10
## Duration in seconds for the expand animation.
@export var vertical_expand_time: float = 0.10
## Controls whose visibility is hidden during collapse/expand and shown when expanded.
@export var nodes_to_hide: Array[Control]

## Vertical size when collapsed (typically 0).
@export var _y_size_collapsed: float = 0.0

## True while a collapse or expand animation is running.
var animating: bool = false
## True when the control is collapsed, false when expanded.
var collapsed: bool = false
## Vertical size when expanded. Set to match the panel's open height.
var _y_size_expanded: float = 0.0
var _initial_pos: Vector2 = Vector2.ZERO
var _expanded_pos: Vector2 = Vector2.ZERO

var _target_size: Vector2 = Vector2.ZERO
var _target_position: Vector2 = Vector2.ZERO
var _anim_duration: float = 0.0
var _anim_elapsed: float = 0.0
var _anim_collapsing: bool = false


## Sets process mode, derives expanded/collapsed positions from scene position, and applies initial state.
func _notification(what: int) -> void:
	if what == NOTIFICATION_READY:
		process_mode = Node.PROCESS_MODE_ALWAYS
		custom_minimum_size = Vector2.ZERO
		_y_size_expanded = size.y # assume expanded y size is the initial y size
		_expanded_pos = position
		_initial_pos = _expanded_pos + Vector2(0.0, _y_size_expanded / 2.0)
		if initial_state == InitialState.COLLAPSED:
			instantCollapseVertical()
		elif initial_state == InitialState.EXPANDED:
			instantExpandVertical()


## Advances the collapse/expand animation each frame. Do not override in subclasses without calling super.
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
			finished_transition.emit(transitions.COLLAPSE_VERTICAL)
		else:
			collapsed = false
			_show_nodes_to_hide()
			finished_transition.emit(transitions.EXPAND_VERTICAL)
		return
	var step_size: float = size.distance_to(_target_size) * (delta / remaining)
	var step_pos: float = position.distance_to(_target_position) * (delta / remaining)
	size = size.move_toward(_target_size, step_size)
	position = position.move_toward(_target_position, step_pos)
	# Keep vertical center fixed at _initial_pos.y so the item stays centered while animating
	position.y = _initial_pos.y - size.y / 2.0
	_anim_elapsed += delta
	

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


## Starts animating the control to its expanded state. No-op if already expanded or if an animation is in progress.
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


## Collapses the control immediately with no animation (size and position set to collapsed state).
func instantCollapseVertical() -> void:
	_hide_nodes_to_hide()
	size.y = _y_size_collapsed
	position = _initial_pos
	collapsed = true
	finished_transition.emit(transitions.COLLAPSE_VERTICAL)


## Expands the control immediately with no animation (size and position set to expanded state).
func instantExpandVertical() -> void:
	_show_nodes_to_hide()
	size.y = _y_size_expanded
	position = _expanded_pos
	collapsed = false
	finished_transition.emit(transitions.EXPAND_VERTICAL)


## Sets visible to true on every node in [member nodes_to_hide].
func _show_nodes_to_hide() -> void:
	for node in nodes_to_hide:
		node.visible = true


## Sets visible to false on every node in [member nodes_to_hide].
func _hide_nodes_to_hide() -> void:
	for node in nodes_to_hide:
		node.visible = false
