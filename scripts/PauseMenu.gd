class_name PauseMenu
extends Control
## Pause menu UI. Handles pause/unpause input and panel visibility.
## Panels in the "pause menu overlay" group open on top of the current panel (both stay visible).
## Other panels use replace behavior: the current panel collapses first, then the new one expands.
## Going back always collapses the top panel and pops it; the new top is expanded if it was collapsed.

@onready var player: Player = get_tree().get_first_node_in_group("players")
@onready var main_center_pause: UICollapseTweener = $CenterButtons/MainCenterPause
@onready var restart_confirm: UICollapseTweener = $CenterButtons/RestartConfirm

signal paused
signal unpaused

@export var main_menu_scene: PackedScene

## Root panel shown when the pause menu first opens (e.g. main pause buttons).
@onready var _root_panel: UICollapseTweener = main_center_pause

## Stack of visible panels: bottom = root, top = front. Overlay panels are all expanded; replace panels leave those below collapsed.
var _panel_stack: Array[UICollapseTweener] = []

## Panel to expand after the current top finishes collapsing (replace behavior). Null if none.
var _pending_show: UICollapseTweener = null

## If true, after the current top panel finishes collapsing we pop it (and close menu if stack becomes empty).
var _pending_go_back: bool = false


func _ready() -> void:
	visible = false
	_connect_panel_transition_signals()
	# Start with menu closed (no panels on stack).
	_panel_stack.clear()
	for panel in _get_all_panels():
		panel.instantCollapseVertical()
	_update_panel_mouse_filters()


func _process(delta: float) -> void:
	Debug.log(_panel_stack)


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


## Makes only the topmost panel in the stack receive mouse input; panels below (and all their descendants) get MOUSE_FILTER_IGNORE.
func _update_panel_mouse_filters() -> void:
	var top: UICollapseTweener = _panel_stack[-1] if not _panel_stack.is_empty() else null
	for panel in _get_all_panels():
		var accept_input: bool = (panel == top)
		_set_mouse_filter_recursive(panel, Control.MOUSE_FILTER_STOP if accept_input else Control.MOUSE_FILTER_IGNORE)


## Sets [param filter] on [param node] and every descendant that is a Control.
func _set_mouse_filter_recursive(node: Node, filter: Control.MouseFilter) -> void:
	if node is Control:
		(node as Control).mouse_filter = filter
	for child in node.get_children():
		_set_mouse_filter_recursive(child, filter)


## When a panel finishes collapsing, run the pending action: show the next panel (replace) or go back (pop).
func _on_panel_finished_transition(transition: UICollapseTweener.transitions, panel: UICollapseTweener) -> void:
	if transition != UICollapseTweener.transitions.COLLAPSE_VERTICAL:
		return
	if _panel_stack.is_empty() or _panel_stack[-1] != panel:
		return

	if _pending_show != null:
		var to_show: UICollapseTweener = _pending_show
		_pending_show = null
		_panel_stack.append(to_show)
		to_show.expandVertical()
		_update_panel_mouse_filters()
		return

	if _pending_go_back:
		_pending_go_back = false
		_panel_stack.pop_back()
		if _panel_stack.is_empty():
			player.pause_menu.visible = false
			unpause()
		else:
			_panel_stack[-1].expandVertical()
		_update_panel_mouse_filters()


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
	_update_panel_mouse_filters()


## Name of the group for panels that open on top without collapsing the current panel (e.g. confirm dialogs).
const OVERLAY_GROUP := "pause menu overlay"

## Shows a panel. Overlay (in [constant OVERLAY_GROUP]): push and expand on top. Else: collapse current, then expand [param panel].
## No-op if [param panel] is already the top. If the menu was closed, opens with root first.
func request_show_panel(panel: UICollapseTweener) -> void:
	if _panel_stack.is_empty():
		open_menu()
		_panel_stack.append(panel)
		panel.expandVertical()
		_update_panel_mouse_filters()
		return
	if _panel_stack[-1] == panel:
		return
	if _is_overlay_panel(panel):
		_panel_stack.append(panel)
		panel.expandVertical()
		_update_panel_mouse_filters()
	else:
		_pending_show = panel
		_panel_stack[-1].collapseVertical()


func _is_overlay_panel(panel: Node) -> bool:
	return panel.is_in_group(OVERLAY_GROUP)


## Collapses only the current top panel; when done, pops it (panels below stay visible). Closes menu if stack becomes empty.
func request_go_back() -> void:
	if _panel_stack.is_empty():
		player.pause_menu.visible = false
		unpause()
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
