# --- License
# File: /client/src/userinterface/client_edit_mode/desktop/scripts/inspector.gd
# Project: OpenMinerva
# Created Date: 10 June 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Control

# Gizmos
var world_gizmos: Array[Dictionary] = []
var my_gizmo: Node
var _gizmo_mode: int = 0
var _gizmo_space_local: bool = true
# Inspector data
var _inspector_selected: TreeItem = null
var _inspector_editing: TreeItem = null
var _inspector_focused: TreeItem = null
var _inspector_opened_tree_nodes: Array[Node] = []
var _inspector_selected_node: Node = null
var _inspector_tree_filters: Array[String] = []
var _inspector_tree_search: String = ""
var _cem_camera: bool = false

# FIXME: You can select the selected spawnable. (Safe but probably should be changed)
# External Libraries / scripts
@onready var _app_spawnable_file_handling_m: Node = get_tree().current_scene.get_node("SpawnableFileHandling")
@onready var app_scene_m: Node = get_tree().current_scene.get_node("SceneManager")
@onready var app_network_m: Node = get_tree().current_scene.get_node("NetworkManager")
@onready var session_spawnable_m: Node
@onready var session_signalbus: Node
@onready var session_players_m: Node
@onready var session_root: Node3D
# UI Elements
@onready var _node_toolbar: Control = get_node("VBoxContainer/Toolbar")
@onready var _node_toolbar_gizmo_control_container: Control = _node_toolbar.get_node("MarginContainer/HBoxContainer/GizmoControl")
@onready var _node_toolbar_gizmo_control_container_misc: Control = _node_toolbar.get_node("MarginContainer/HBoxContainer/GizmoControlMisc")
@onready var _node_toolbar_spawnable_count: Control = _node_toolbar.get_node("MarginContainer/HBoxContainer/SpawnableCount")
@onready var _node_toolbar_player_count: Control = _node_toolbar.get_node("MarginContainer/HBoxContainer/PlayerCount")
@onready var _node_crosshair: Node = get_tree().current_scene.get_node("Crosshair")
@onready var _inspector_popup: Node = get_node("InspectorPopup")
@onready var _inspector_add_node_window: Node = get_node("AddNodeWindow")
@onready var _inspector_filter_search: LineEdit = get_node("VBoxContainer/HBoxContainer/HSplitContainer/MarginContainer/VBoxContainer/Container/VBoxContainer/InputString/MarginContainer/HBoxContainer/MarginContainer/LineEdit")
@onready var _inspector_filters: Node = get_node("VBoxContainer/HBoxContainer/HSplitContainer/MarginContainer/VBoxContainer/Container/VBoxContainer/Filters/HBoxContainer")
@onready var _node_property_editor: Node = get_node("VBoxContainer/HBoxContainer/HSplitContainer/Properties")
# UI Inspector
@onready var _inspector_tree: Tree = get_node("VBoxContainer/HBoxContainer/HSplitContainer/MarginContainer/VBoxContainer/Container/VBoxContainer/MarginContainer/Tree")


func _ready() -> void:
	_set_state(false)
	_add_signalbus_event_listeners()
	_add_gizmo_event_listeners()
	_add_button_event_listeners()
	_add_misc_event_listeners()

	_add_drag_events()

	_inspector_popup.visible = false

	_inspector_build()
	_gizmo_set_mode()
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

	if event.is_action_pressed("cem_activate"):
		if StateManager.cem == false:
			Events.emit_signal("dash_set_state", false)
			Events.emit_signal("cem_set_state", true)
		else:
			Events.emit_signal("dash_set_state", false)
			Events.emit_signal("cem_set_state", false)

		StateManager.update_mouse_state()

		get_viewport().set_input_as_handled()

	if event.is_action_pressed("cem_camera"):
		_cem_camera = !_cem_camera
		_cem_camera_state(_cem_camera)

	return


func _can_drop_data(mouse_position: Vector2, data: Variant):
	var _target_item: TreeItem = _inspector_tree.get_item_at_position(mouse_position)
	var _dragged_item: TreeItem = data["item"]

	if _dragged_item == _target_item:
		# Don't parent to self.
		return false

	# Don't parent to any of own children.
	# FIXME: Find safe ways to escape this while loop.
	var _checking = _target_item
	while _checking:
		if _checking == _dragged_item:
			return false
		_checking = _checking.get_parent()

	# TODO: Check to see if node is inside of root.

	return true


func _drop_data(mouse_position: Vector2, data: Variant):
	var _dragged_node: Node = data["node"]
	var _target_tree_item: TreeItem = _inspector_tree.get_item_at_position(mouse_position)
	var _target_node: Node

	if _target_tree_item == null:
		_target_node = session_root
		await session_spawnable_m.parent_spawnable(int(_dragged_node.name), -1)
		return

	_target_node = _target_tree_item.get_metadata(0)

	await session_spawnable_m.parent_spawnable(int(_dragged_node.name), int(_target_node.name))

	_inspector_build()


func _get_drag_data(mouse_position: Vector2):
	var _target_tree_item: TreeItem = _inspector_tree.get_item_at_position(mouse_position)

	if _target_tree_item && _target_tree_item.get_parent():
		return { "item": _target_tree_item, "node": _target_tree_item.get_metadata(0) }

	return null


func _add_drag_events() -> void:
	_inspector_tree.set_drag_forwarding(
		self._get_drag_data,
		self._can_drop_data,
		self._drop_data,
	)
	return


# Signals and other event listeners
func _add_signalbus_event_listeners() -> void:
	GlobalLogger.log("Adding signal bus event listeners to the inspector.")
	Events.cem_set_state.connect(_set_state)
	Events.dash_session_changed.connect(_on_session_changed)
	return


func _add_gizmo_event_listeners() -> void:
	var _node_children: Array[Node] = _node_toolbar_gizmo_control_container.get_children()
	var _misc_node_children: Array[Node] = _node_toolbar_gizmo_control_container_misc.get_children()

	for node_index in _node_children.size():
		var _node = _node_children[node_index]
		_node.get_node("Button").pressed.connect(_gizmo_set_mode)

	_misc_node_children[0].get_node("Button").pressed.connect(_gizmo_set_mode)
	return


func _add_button_event_listeners() -> void:
	_inspector_popup.entry_clicked.connect(_inspector_popup_button_pressed)
	_inspector_tree.item_mouse_selected.connect(_inspector_tree_item_mouse_selected)

	_inspector_filter_search.text_changed.connect(_inspector_search_changed)

	# When clicking on a filter button, apply the filter immediately.
	for _filter_button in _inspector_filters.get_children():
		_filter_button.get_node("Button").pressed.connect(
			func():
				_inspector_get_filters()
				_inspector_build()
		)

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

		_inspector_selected_node = _inspector_selected.get_metadata(0)
		_set_npe_state(_inspector_selected_node != null)

		_select(int(_inspector_selected.get_metadata(0).name))
		return

	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		_inspector_selected = _inspector_tree.get_item_at_position(mouse_position)

		if _inspector_selected == null:
			return

		_inspector_selected_node = _inspector_selected.get_metadata(0)
		_set_npe_state(_inspector_selected_node != null)

		var _mouse_pos = _inspector_tree.get_global_mouse_position()
		_inspector_popup.position = _mouse_pos
		_inspector_popup.visible = true
	return


func _set_state(state: bool) -> void:
	GlobalLogger.log("Inspector state is being set to '%s'." % state)
	_gizmo_visibility(state)
	_inspector_build()
	visible = state
	_node_crosshair.visible = !state
	return


func _on_node_created(_node: Node) -> void:
	if session_root == null:
		session_root = app_scene_m.get_master_root(app_scene_m.active_session)

	GlobalLogger.log("Node created.")
	_inspector_build()
	return


func _on_node_destroyed(node_entry: Dictionary) -> void:
	if session_root == null:
		session_root = app_scene_m.get_master_root(app_scene_m.active_session)

	GlobalLogger.log("Node destroyed.")

	# Deselect the node if selected.
	if my_gizmo:
		my_gizmo.deselect(node_entry.node)

	await get_tree().process_frame
	_inspector_build()
	return


func _on_node_metadata_changed(_node_entry: Node) -> void:
	_inspector_build()
	return


func _on_session_changed(_session_id: String) -> void:
	var _session_master: Node3D = app_scene_m.get_master_scene(_session_id)
	session_signalbus = _session_master.get_node("SignalBus")
	session_spawnable_m = _session_master.get_node("SpawnableManager")
	session_players_m = _session_master.get_node("PlayerManager")
	session_root = app_scene_m.get_master_root(app_scene_m.active_session)

	_inspector_selected = null
	_inspector_editing = null
	_inspector_focused = null

	if session_signalbus.is_connected("node_created", _on_node_created) == false:
		session_signalbus.node_created.connect(_on_node_created)
		session_signalbus.node_destroyed.connect(_on_node_destroyed)
		session_signalbus.node_metadata_change.connect(_on_node_metadata_changed)

	_inspector_build()
	return


# User Interface
func _inspector_build(root_node: Node = session_root) -> void:
	if root_node == null:
		GlobalLogger.log("Invalid root node: '%s'" % root_node, Enum.LogLevel.WARNING)
		return

	var _database: Array[Dictionary] = session_spawnable_m._registry.get_all_spawnable()

	var _total_spawnable_label: String = str(_database.size())
	var _total_player_label: String = str(session_players_m.get_player_count())

	GlobalLogger.log("Generating the inspector view with parent '%s'." % root_node)
	_inspector_save_openness()
	_inspector_clear()
	var _inspector_root = _inspector_tree.create_item()
	_inspector_add_node(root_node, _inspector_root)

	if _inspector_tree_filters.size() > 0 || _inspector_tree_search != "":
		_inspector_apply_filters()

	# Update the Toolbar counts.
	_node_toolbar_spawnable_count.update_meta(_total_spawnable_label)
	_node_toolbar_player_count.update_meta(_total_player_label)

	return


func _inspector_save_openness() -> void:
	# Parse the entire tree, and save node values that are open
	_inspector_opened_tree_nodes = []
	var _item = _inspector_tree.get_root()

	# TODO: Breakout / Safety!
	while _item:
		if _item.is_collapsed() == true:
			_item = _item.get_next_in_tree()
			continue

		# Save the item to the list
		var _node = _item.get_metadata(0)
		if _node != null:
			_inspector_opened_tree_nodes.append(_item.get_metadata(0))

		_item = _item.get_next_in_tree()

	return


func _inspector_add_node(node: Node, parent: TreeItem) -> void:
	if node.get_meta("scene_node", false) == false:
		return

	var _tree_node = _inspector_tree.create_item(parent)

	if _tree_node == null:
		return

	var _tree_icon = NSB.get_entry(node.get_class()).icon
	var _is_collapsed = !_inspector_opened_tree_nodes.has(node)

	_tree_node.set_text(0, node.get_meta("pretty_name", node.name))
	_tree_node.set_icon(0, _tree_icon)
	_tree_node.set_icon_max_width(0, 20)
	_tree_node.set_metadata(0, node)
	_tree_node.collapsed = _is_collapsed

	if _inspector_selected_node == node:
		_inspector_tree.set_selected(_tree_node, 0)

	for child in node.get_children():
		_inspector_add_node(child, _tree_node)
	return


# Inspector filters
func _inspector_apply_filters():
	var _all_tree_items: Array[TreeItem] = _inspector_get_all_tree_entries(_inspector_tree)
	var _valid_nodes: Array = []

	for _tree_item in _all_tree_items:
		var _tree_item_node = _tree_item.get_metadata(0)
		if _tree_item_node == null:
			GlobalLogger.log("Could not find the associated node for entry '%s'" % _tree_item.get_text(0), Enum.LogLevel.WARNING)
			continue

		# TODO: This is probably expensive to run, surely there is a better way to get this information.
		# Would adding this to the metadata of the tree listing be more performant?
		var _nsb_entry = NSB.get_entry(_tree_item_node.get_class())

		if _tree_item_node.get_meta("pretty_name", "").contains(_inspector_tree_search):
			# If the pretty name in the node contains text that matches the search.
			for _ancestor in _inspector_get_all_tree_ancestors(_tree_item):
				# Get all tree items that lead to this tree item. From listing up through each parent.
				if _ancestor not in _valid_nodes:
					# If we do not already have the tree item added to the list, add it.
					_valid_nodes.append(_ancestor)

		if "tags" in _nsb_entry:
			# Does the NSB DB entry have the "tags" field? (Error check)
			for _node_tag in _nsb_entry.tags:
				# For each of the tags in the DB tags field.
				if _node_tag in _inspector_tree_filters:
					# Does this tag exist in the active inspector filter?
					for _ancestor in _inspector_get_all_tree_ancestors(_tree_item):
						# Get all tree items that lead to this tree item. From listing up through each parent.
						if _ancestor not in _valid_nodes:
							# If we do not already have the tree item added to the list, add it.
							_valid_nodes.append(_ancestor)

	for _tree_item in _all_tree_items:
		# For each item in the tree, set the visible state based the items presense in the _valid_nodes variable, and if the name matches search.
		var _is_visible: bool = false

		if _valid_nodes.has(_tree_item):
			_is_visible = true

		elif _tree_item.get_text(0).contains(_inspector_tree_search):
			_is_visible = true

		_tree_item.set_visible(_is_visible)
	return


func _inspector_get_filters():
	_inspector_tree_filters = []

	for child in _inspector_filters.get_children():
		if child.get_node("Button").button_pressed:
			_inspector_tree_filters.append(child.name)

	return


func _inspector_search_changed(text) -> void:
	_inspector_tree_search = text
	_inspector_build()
	return


func _inspector_get_all_tree_entries(tree: Tree) -> Array[TreeItem]:
	var _tree_items: Array[TreeItem] = []
	var _tree_current = tree.get_root()

	# NOTE: There is not a safety check for this, I hope I wont need one here.
	while _tree_current:
		_tree_items.append(_tree_current)
		_tree_current = _tree_current.get_next_in_tree()

	return _tree_items


func _inspector_get_all_tree_ancestors(starting_item: TreeItem) -> Array[TreeItem]:
	var _tree_ancestors: Array[TreeItem] = []
	var _tree_item_parent: TreeItem = starting_item.get_parent()

	_tree_ancestors.append(starting_item)
	_tree_ancestors.append(_tree_item_parent)

	# NOTE: There is not a safety check for this, I hope I wont need one here.
	while _tree_item_parent:
		_tree_item_parent = _tree_item_parent.get_parent()
		if _tree_item_parent != null:
			_tree_ancestors.append(_tree_item_parent)

	return _tree_ancestors


# Inspector events
func _inspector_item_edited() -> void:
	var _node: Node = _inspector_editing.get_metadata(0)
	var _new_name: String = _inspector_editing.get_text(0)

	_inspector_editing.set_editable(0, false)
	session_spawnable_m.set_metadata.rpc(int(_node.name), "pretty_name", _new_name)


func _inspector_clear() -> void:
	GlobalLogger.log("Clearing the inspector.")
	_inspector_tree.clear()
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
			_inspector_add_node_window.parent_node_id = int(_node.name)
			_inspector_add_node_window.show()
		"Remove":
			await session_spawnable_m.destroy_spawnable(int(_node.name))
		"Rename":
			_inspector_selected.set_editable(0, true)
			_inspector_tree.edit_selected()
			_inspector_editing = _inspector_selected
		"Save":
			GlobalLogger.log("Saving spawnable.")
			_app_spawnable_file_handling_m.save_spawnable(_node, Enum.SpawnableType.ITEM)
		_:
			GlobalLogger.log("Unhandled inspector popup selection", Enum.LogLevel.WARNING)
	return


func _inspector_spawn_node(type: String, parent: int) -> void:
	GlobalLogger.log("Spawning node type '%s' with parent '%s'" % [type, parent])
	var _entity = await session_spawnable_m.create_spawnable(type, parent)
	_select(int(_entity.name))
	# TODO: Gizmo select the new entity
	return


func _select(target_node: int) -> void:
	if target_node == 0:
		GlobalLogger.log("Invalid node selected", Enum.LogLevel.WARNING)
		return

	if my_gizmo != null:
		GlobalLogger.log("Gizmo exists, deleting")
		_gizmo_delete()

	# TODO: Validate that the gizmo was created and did not error.
	my_gizmo = await session_spawnable_m.create_spawnable("Gizmo")

	var _node_db_entry = session_spawnable_m.get_by_id(target_node)
	session_spawnable_m.select.rpc(target_node, int(my_gizmo.name))

	my_gizmo.mode = _gizmo_mode
	my_gizmo.use_local_space = _gizmo_space_local

	_node_property_editor.get_node_properties(_node_db_entry.node)

	# HACK: Update ALL of the node properties after a transformation was done.
	# This should be happening somewhere else that is more stable / live.
	my_gizmo.transform_end.connect(func(_mode): _node_property_editor.update_node_properties(_node_db_entry.node))

	return


func _gizmo_delete() -> void:
	my_gizmo.clear_selection()
	await session_spawnable_m.destroy_spawnable(int(my_gizmo.name))
	return


func _gizmo_set_mode() -> void:
	var _gizmo_modes: Dictionary
	var _node_children: Array[Node] = _node_toolbar_gizmo_control_container.get_children()
	var _misc_node_children: Array[Node] = _node_toolbar_gizmo_control_container_misc.get_children()

	for node_index in _node_children.size():
		var _node = _node_children[node_index]
		var _dict_name = _node.name.to_lower()
		var _is_active = _node.get_node("Button").button_pressed

		_gizmo_modes[_dict_name] = _is_active

	_gizmo_mode = 0
	_gizmo_space_local = !_misc_node_children[0].get_node("Button").button_pressed

	if _gizmo_modes.get("transform", false):
		_gizmo_mode |= Gizmo3D.ToolMode.MOVE
	if _gizmo_modes.get("rotation", false):
		_gizmo_mode |= Gizmo3D.ToolMode.ROTATE
	if _gizmo_modes.get("scale", false):
		_gizmo_mode |= Gizmo3D.ToolMode.SCALE

	if my_gizmo != null:
		my_gizmo.mode = _gizmo_mode
		my_gizmo.use_local_space = _gizmo_space_local

	return


func _gizmo_visibility(to_set_visible: bool = false) -> void:
	var _gizmo_target_mode = 0

	if to_set_visible == true:
		_gizmo_target_mode = _gizmo_mode

	if my_gizmo:
		my_gizmo.show_selection_box = to_set_visible
		my_gizmo.mode = _gizmo_target_mode

	for gizmo in world_gizmos:
		gizmo.show_selection_box = to_set_visible
		gizmo.mode = _gizmo_target_mode
	return


# CEM Camera
func _cem_camera_state(state: bool) -> void:
	var _active_session_id = app_scene_m.active_session
	var _session_api = app_network_m.registry.get_session(_active_session_id).api
	var _player_id: int = _session_api.get_unique_id()
	var _player_db = session_players_m.players[str(_player_id)]
	var _player_node: Node3D

	# HACK: Hardcoded fix for force host spawn.
	# The host is forcefully spawned into a instance as it is created, bypassing the database entirely.
	if _player_db == null:
		_player_node = session_root.get_node("1")
	else:
		_player_node = session_players_m.players[str(_player_id)].node

	_player_node._cem_camera_state(state)
	Events.emit_signal("cem_camera_state", state)
	return


# Node Property Editor
func _set_npe_state(state: bool) -> void:
	_node_property_editor.visible = state
	return
