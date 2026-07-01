# --- License
# File: /client/src/userinterface/client_edit_mode/desktop/scripts/inspector_new.gd
# Project: OpenMinerva
# Created Date: 10 June 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Control

# FIXME: Selecting Gizmo crashes

# External Libraries / scripts
# FIXME: DevSpawnableManager node
@onready var dev_spawn_m: Node = get_tree().current_scene.get_node("DevSpawnManager")
@onready var app_scene_m: Node = get_tree().current_scene.get_node("SceneManager")
@onready var session_spawnable_m: Node
@onready var session_signalbus: Node
@onready var session_root: Node3D

# Gizmos
var world_gizmos: Array[Dictionary] = []
var my_gizmo: Node

# UI Elements
@onready var _node_toolbar: Control = get_node("VBoxContainer/Toolbar")
@onready var _node_toolbar_gizmo_control_container: Control = _node_toolbar.get_node("MarginContainer/HBoxContainer/GizmoControlMisc")
@onready var _node_toolbar_spawnable_count: Control = _node_toolbar.get_node("MarginContainer/HBoxContainer/SpawnableCount")
@onready var crosshair: Node = get_tree().current_scene.get_node("Crosshair")
@onready var _inspector_popup: Node = get_node("InspectorPopup")
@onready var _inspector_add_node_window: Node = get_node("Popup")

# UI Inspector
@onready var _inspector_tree: Tree = get_node("VBoxContainer/HBoxContainer/HSplitContainer/MarginContainer/VBoxContainer/Container/VBoxContainer/MarginContainer/Tree")

# Inspector data
var _inspector_selected: TreeItem = null
var _inspector_editing: TreeItem = null
var _inspector_focused: TreeItem = null

func _ready() -> void:
	_set_state(false)
	_add_signalbus_event_listeners()
	_add_button_event_listeners()
	_add_misc_event_listeners()

	_inspector_popup.visible = false

	# TODO: Proper wait until building the inspector.
	await get_tree().process_frame

	_inspector_build()
	return

func _input(event: InputEvent):
	# Used to remove focus of the search area when clicking inside of the scene.
	if event is InputEventMouseButton && event.pressed:
		var focused = get_viewport().gui_get_focus_owner()
		if focused:
			focused.release_focus()

		# Close the inspector popup
		if _inspector_popup.visible == true:
			var _rect = _inspector_popup.get_global_rect()
			var _mouse_pos = event.position

			if _rect.has_point(_mouse_pos) == false:
				_inspector_popup.visible = false

# Signals and other event listeners
func _add_signalbus_event_listeners() -> void:
	GlobalLogger.log("Adding signal bus event listeners to the inspector.")
	Events.cem_set_state.connect(_set_state)
	Events.dash_session_changed.connect(_on_session_changed)
	# TODO: Events.cem_set_gizmo_state.connect(_toggle_gizmos)

func _add_button_event_listeners() -> void:
	_inspector_popup.entry_clicked.connect(_inspector_popup_button_pressed)
	_inspector_tree.item_mouse_selected.connect(_inspector_tree_item_mouse_selected)
	return

func _add_misc_event_listeners() -> void:
	_inspector_add_node_window.selection.connect(_inspector_spawn_node)
	_inspector_tree.item_edited.connect(_inspector_item_edited)
	return

func _inspector_tree_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_LEFT:
		_inspector_selected = _inspector_tree.get_item_at_position(mouse_position)

		if _inspector_selected == null:
			return

		_select(int(_inspector_selected.get_metadata(0).name))
		return

	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		_inspector_selected = _inspector_tree.get_item_at_position(mouse_position)

		if _inspector_selected == null:
			return

		var _mouse_pos = _inspector_tree.get_global_mouse_position()
		_inspector_popup.position = _mouse_pos
		_inspector_popup.visible = true
	return

func _set_state(state: bool) -> void:
	GlobalLogger.log("Inspector state is being set to '%s'." % state)
	visible = state
	crosshair.visible = !state
	return

func _on_node_created(node: Node) -> void:
	# TODO: Instead of rebuilding the entire tree, just update the respective entry.
	GlobalLogger.log("Inspector: Node created.")
	_inspector_build()
	return

func _on_node_destroyed(node: String) -> void:
	# TODO: Instead of rebuilding the entire tree, just update the respective entry.
	GlobalLogger.log("Inspector: Node destroyed.")
	_inspector_build()
	return

func _on_session_changed() -> void:
	session_signalbus = app_scene_m.get_master_scene(app_scene_m.active_session).get_node("SignalBus")
	session_spawnable_m = app_scene_m.get_master_scene(app_scene_m.active_session).get_node("SpawnableManager")
	session_root = app_scene_m.get_master_root(app_scene_m.active_session)

	_inspector_selected = null
	_inspector_editing = null
	_inspector_focused = null

	if session_signalbus.is_connected("node_created", _on_node_created) == false:
		session_signalbus.node_created.connect(_on_node_created)
		session_signalbus.node_destroyed.connect(_on_node_destroyed)
	return

# User Interface
func _inspector_build(root_node: Node = session_root) -> void:
	# TODO: Proper wait until building the inspector.
	await get_tree().process_frame

	GlobalLogger.log("Generating the inspector view with parent '%s'." % root_node)
	_inspector_clear()
	var _inspector_root = _inspector_tree.create_item()
	_inspector_add_node(root_node, _inspector_root)
	return

func _inspector_add_node(node: Node, parent: TreeItem) -> void:
	if node.get_meta("scene_node", false) == false:
		GlobalLogger.log("Ignoring node '%s' in the inspector." % node)
		return

	var _tree_node = _inspector_tree.create_item(parent)
	var _tree_icon = _get_node_icon(node.get_class())

	_tree_node.set_text(0, node.get_meta("pretty_name", node.name))
	_tree_node.set_icon(0, _tree_icon)
	_tree_node.set_icon_max_width(0, 20)
	_tree_node.set_metadata(0, node)


	for child in node.get_children():
		_inspector_add_node(child, _tree_node)
	return

func _inspector_item_edited() -> void:
	_inspector_editing.set_editable(0, false)
	_inspector_editing.get_metadata(0).set_meta("pretty_name", _inspector_editing.get_text(0))

func _get_node_icon(class_n: String) -> Texture2D:
	var _schema_index = NSB.get_node_index(class_n)
	var _icon = NSB.get_formatted(_schema_index).icon
	return _icon

func _inspector_clear() -> void:
	GlobalLogger.log("Clearing the inspector.")
	_inspector_tree.clear()
	return

func _node_selected(node: Node) -> void:
	return

func _inspector_popup_button_pressed(label: String) -> void:
	GlobalLogger.log("Pressed button: '%s' on '%s'" % [label, _inspector_selected.get_text(0)])
	_inspector_popup.visible = false

	var _node = _inspector_selected.get_metadata(0)
	if _node == null:
		GlobalLogger.log("Tried to preform an action on an invalid node.", Enum.LogLevel.WARNING)
		_inspector_build()
		return

	match label:
		"New":
			_inspector_add_node_window.set_meta("selected_node", _node)
			_inspector_add_node_window.show()
		"Remove":
			await session_spawnable_m.destroy(int(_node.name))
		"Rename":
			_inspector_selected.set_editable(0, true)
			_inspector_editing = _inspector_selected
		"Save":
			GlobalLogger.log("Saving spawnable.")
			dev_spawn_m.save_spawnable(_node)
		_:
			GlobalLogger.log("Unhandled inspector popup selection", Enum.LogLevel.WARNING)
	return

func _inspector_spawn_node(type: int, parent: int) -> void:
	GlobalLogger.log("Spawning node type '%s' with parent '%s'" % [type, parent])
	var _entity = await session_spawnable_m.create(type, parent)
	_select(int(_entity.name))
	# TODO: Gizmo select the new entity
	return

func _select(target_node: int) -> void:
	var _node_db_entry = session_spawnable_m.get_by_id(target_node)
	var _gizmo_schema_index = NSB.get_node_index("Gizmo")

	if my_gizmo != null:
		_gizmo_delete()

	if _node_db_entry == {}:
		GlobalLogger.log("Tried to select a node that should not exist!", Enum.LogLevel.ERROR)
		return

	my_gizmo = await session_spawnable_m.create(_gizmo_schema_index)
	# TODO: Add to array of Gizmos
	my_gizmo.select(_node_db_entry.node)

func _gizmo_delete() -> void:
	my_gizmo.clear_selection()
	await session_spawnable_m.destroy(int(my_gizmo.name))
	return
