class_name PauseMenu
extends Control
## Pause menu UI. Handles pause/unpause input and panel visibility.
## Uses a panel stack and collapse-then-expand sequencing so only one panel is visible
## at a time and transitions wait for the current panel to collapse before expanding the next.

@onready var player: Player = get_tree().get_first_node_in_group("players")
@onready var main_center_pause: UICollapseTweener = $CenterButtons/MainCenterPause
@onready var restart_confirm: UICollapseTweener = $CenterButtons/RestartConfirm

signal paused
signal unpaused

@export var main_menu_scene: PackedScene

## Root panel shown when the pause menu first opens (e.g. main pause buttons).
@onready var _root_panel: UICollapseTweener = main_center_pause

## Stack of panels: bottom is root, top is the one currently visible. Only the top is expanded.
var _panel_stack: Array[UICollapseTweener] = []

## Panel to expand after the current top panel finishes collapsing. Null if no transition pending.
var _pending_show: UICollapseTweener = null

## If true, after the current top panel collapses we go back (pop stack and expand new top, or close menu).
var _pending_go_back: bool = false


func _ready() -> void:
	visible = false
	_connect_panel_transition_signals()
	# Start with menu closed (no panels on stack).
	_panel_stack.clear()
	for panel in _get_all_panels():
		panel.instantCollapseVertical()


func _connect_panel_transition_signals() -> void:
	for panel in _get_all_panels():
		if not panel.finished_transition.is_connected(_on_panel_finished_transition.bind(panel)):
			panel.finished_transition.connect(_on_panel_finished_transition.bind(panel))


## Returns all pause menu panels from the "pause menu panels" group (must be UICollapseTweener).
func _get_all_panels() -> Array[UICollapseTweener]:
	var panels: Array[UICollapseTweener] = []
	for node in get_tree().get_nodes_in_group("pause menu panels"):
		if node is UICollapseTweener:
			panels.append(node)
	return panels


## When a panel finishes collapsing or expanding, run the next pending action (show another panel or go back).
func _on_panel_finished_transition(transition: UICollapseTweener.transitions, panel: UICollapseTweener) -> void:
	if transition != UICollapseTweener.transitions.COLLAPSE_VERTICAL:
		return
	# Only react when the panel that collapsed is the current top (the one we asked to collapse).
	if _panel_stack.is_empty() or _panel_stack[-1] != panel:
		return

	if _pending_show != null:
		var to_show: UICollapseTweener = _pending_show
		_pending_show = null
		_panel_stack.append(to_show)
		to_show.expandVertical()
		return

	if _pending_go_back:
		_pending_go_back = false
		_panel_stack.pop_back()
		if _panel_stack.is_empty():
			player.pause_menu.visible = false
			unpause()
		else:
			_panel_stack[-1].expandVertical()


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if Input.is_action_just_pressed("pause"):
			if get_pause():
				request_go_back()
			else:
				pause()
				open_menu()


## Opens the pause menu by showing the root panel (no transition; menu was closed).
func open_menu() -> void:
	player.pause_menu.visible = true
	_panel_stack.clear()
	_panel_stack.append(_root_panel)
	_root_panel.expandVertical()


## Asks to show a panel: collapses the current top, then expands [param panel] when collapse finishes.
## No-op if [param panel] is already the top of the stack. If the menu was closed, opens with root first.
func request_show_panel(panel: UICollapseTweener) -> void:
	if _panel_stack.is_empty():
		open_menu()
		return
	if _panel_stack[-1] == panel:
		return
	_pending_show = panel
	_panel_stack[-1].collapseVertical()


## Collapses the current top panel; when done, pops the stack and expands the new top (or closes menu if stack becomes empty).
func request_go_back() -> void:
	if _panel_stack.is_empty():
		player.pause_menu.visible = false
		unpause()
		return
	if _panel_stack.size() == 1:
		# Going back from root = close menu and unpause.
		_pending_go_back = true
		_panel_stack[-1].collapseVertical()
		return
	_pending_go_back = true
	_panel_stack[-1].collapseVertical()


func pause() -> void:
	if get_tree().paused:
		return
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	paused.emit()


func unpause() -> void:
	if not get_tree().paused:
		return
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	unpaused.emit()


func get_pause() -> bool:
	return get_tree().paused


func _on_resume_pressed() -> void:
	request_go_back()
	# If we were on root, request_go_back() will collapse and then hide + unpause.
	# So we don't call unpause() again here; it's done in _on_panel_finished_transition.


func _on_options_pressed() -> void:
	pass


func _on_restart_pressed() -> void:
	request_show_panel(restart_confirm)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_restart_confirm_pressed() -> void:
	LoadHandler.reloadCurrentLevel()


func _on_restart_cancel_pressed() -> void:
	request_go_back()
