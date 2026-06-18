extends Node

var gizmos: Array[Dictionary] = []
var _clicked_item: TreeItem = null

@onready var tree_view: Tree = get_node("MarginContainer/VBoxContainer/Container/VBoxContainer/MarginContainer/Tree")
@onready var scene_m = get_tree().current_scene.get_node("SceneManager")
@onready var dev_spawn_m = get_tree().current_scene.get_node("DevSpawnManager")
@onready var spawnable_m: Node
@onready var session_signalbus: Node
@onready var inspector_popup_menu = $InspectorPopup
@onready var gizmo_popup_menu = $GizmoPopup
@onready var session_root: Node
@onready var selection_ui: Tree = get_node("MarginContainer/VBoxContainer/SelectionArea/VBoxContainer/SelectionContainer/Selections")


func _ready() -> void:
	_build_add_node_popup()

	# Instance signals
	Events.dash_session_changed.connect(_session_changed)
	Events.cem_set_gizmo_state.connect(_toggle_gizmos)
	Events.cem_set_state.connect(_set_cem_state)

	tree_view.item_mouse_selected.connect(_on_tree_item_mouse_selected)
	inspector_popup_menu.id_pressed.connect(_on_inspector_popup_menu_id_pressed)

	selection_ui.item_mouse_selected.connect(_on_gizmo_item_selected)
	gizmo_popup_menu.id_pressed.connect(_on_gizmo_popup_pressed)

	inspector_popup_menu.hide()
	pass


func populate_tree_from_node(_node: Variant = ""):
	# Wait a frame to get the updated scene from when it was called.
	# This should be changed in the future when I learn how to properly wait for the scene to update before trying to update the inspector.
	await get_tree().process_frame
	await get_tree().process_frame
	tree_view.clear()
	if not session_root:
		GlobalLogger.log("No session root defined.", Enum.LogLevel.ERROR)
		return

	var tree_root = tree_view.create_item()

	add_node_to_tree(session_root, tree_root)


# FIXME: The open-ness of the current view is not maintained when refreshing the tree view.
func add_node_to_tree(node: Node, parent_item: TreeItem):
	if node.get_meta("scene_node", false):
		var item = tree_view.create_item(parent_item)

		item.set_text(0, node.get_meta("pretty_name", node.name))
		var icon_texture = get_class_icon(node.get_meta("pretty_name", node.get_class()))
		item.set_icon(0, icon_texture)
		item.set_metadata(0, node)

		for child in node.get_children():
			add_node_to_tree(child, item)


# FIXME: Add this function to the NSB class, and add safe fallbacks.
func get_class_icon(class_n: String) -> Texture2D:
	var schema_index = NSB.get_node_index(class_n)
	var icon = NSB.get_formatted(schema_index).icon
	if schema_index == -1:
		return load("res://resources/icons/godot/%s.svg" % class_n)
	return icon


func popupmenu_populate_generic() -> void:
	for i in inspector_popup_menu.item_count:
		inspector_popup_menu.remove_item(0)
	inspector_popup_menu.add_item("Add Child", 0)
	inspector_popup_menu.add_item("Remove Node", 1)
	inspector_popup_menu.add_item("Select", 2)
	inspector_popup_menu.add_item("Save", 3)
	inspector_popup_menu.add_item("Load", 4)
	return


func _on_gizmo_popup_pressed(id: int) -> void:
	var gizmo_node = _clicked_item.get_metadata(0)
	match id:
		0:
			_set_active_gizmo(int(gizmo_node.name))
		1:
			_gizmo_delete(int(gizmo_node.name))
	return


func _on_node_destroyed(node_name: String) -> void:
	var _node = spawnable_m.get_by_id(int(node_name)).node
	for gizmo in gizmos:
		if gizmo.node.is_selected(_node):
			gizmo.node.deselect(_node)
			if gizmo.node.get_selected_count() == 0:
				_gizmo_delete(gizmo.id)

	_update_selection_ui()
	return


func _set_cem_state(state: bool) -> void:
	_toggle_gizmos(state)
	return


func _session_changed():
	session_root = scene_m.get_master_root(scene_m.active_session)
	spawnable_m = scene_m.get_master_scene(scene_m.active_session).get_node("SpawnableManager")
	session_signalbus = scene_m.get_master_scene(scene_m.active_session).get_node("SignalBus")

	if session_signalbus.is_connected("node_created", populate_tree_from_node) == false:
		session_signalbus.node_created.connect(populate_tree_from_node)
		session_signalbus.node_destroyed.connect(populate_tree_from_node)
		session_signalbus.node_destroyed.connect(_on_node_destroyed)
	populate_tree_from_node()


func _on_tree_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int):
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		_clicked_item = tree_view.get_item_at_position(mouse_position)

		if _clicked_item:
			var global_pos = tree_view.get_global_mouse_position()
			popupmenu_populate_generic()
			inspector_popup_menu.position = global_pos
			inspector_popup_menu.popup()


func _on_gizmo_item_selected(mouse_position: Vector2, mouse_button_index: int):
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		_clicked_item = selection_ui.get_item_at_position(mouse_position)

		if _clicked_item:
			var global_pos = selection_ui.get_global_mouse_position()
			gizmo_popup_menu.position = global_pos
			gizmo_popup_menu.popup()


func _build_add_node_popup() -> void:
	var valid_options = NSB.get_valid()
	var tree_node = get_node("Popup").get_node("PanelContainer/ItemList")
	tree_node.item_activated.connect(_on_item_activated)

	for node in valid_options:
		var schema_index = NSB.get_node_index(node)
		var schema_listing = NSB.get_formatted(schema_index)
		var _item = tree_node.add_item(schema_listing.pretty_name, schema_listing.icon)
	return


func _on_item_activated(index: int) -> void:
	var popup = get_node("Popup")
	var tree_node = get_node("Popup").get_node("PanelContainer/ItemList")
	var item_text = tree_node.get_item_text(index)
	var item_type = NSB.get_node_index(item_text)

	var parent_node = popup.get_meta("selected_node")
	if parent_node == null:
		GlobalLogger.log("Tried to add a child to an invalid node.", Enum.LogLevel.WARNING)
		populate_tree_from_node()

		return

	var entity = await spawnable_m.create(item_type, int(parent_node.name))
	# TODO: Handle failed entity creation request.
	_gizmo_new(int(entity.name))

	return


func _on_inspector_popup_menu_id_pressed(id: int):
	if _clicked_item:
		var node = _clicked_item.get_metadata(0)
		if node == null && id != 0:
			GlobalLogger.log("Tried to preform an action on an invalid node.", Enum.LogLevel.WARNING)
			populate_tree_from_node()
			return
		match id:
			0:
				get_node("Popup").set_meta("selected_node", node)
				get_node("Popup").visible = true
			1:
				var _name = node.name
				if node.get_meta("pretty_name") == "Gizmo":
					_gizmo_delete(int(_name))
					return

				await spawnable_m.destroy(int(_name))
			2:
				if gizmos.size() > 0:
					var target_gizmo_node = gizmos.back().node
					_gizmo_add(int(target_gizmo_node.name), int(node.name))
					return
				_gizmo_new(int(node.name))
			3:
				GlobalLogger.log("Saving spawnable.")
				dev_spawn_m.save_spawnable(node)
			4:
				GlobalLogger.log("Loading spawnable.")
				dev_spawn_m.load_spawnable(session_root)


func _update_selection_ui() -> void:
	selection_ui.clear()

	selection_ui.create_item()

	for gizmo in gizmos:
		var gizmo_root = selection_ui.create_item()
		gizmo_root.set_text(0, "Gizmo")
		gizmo_root.set_icon(0, get_class_icon("Gizmo"))
		gizmo_root.set_metadata(0, gizmo.node)

		# TODO: Show all children of nodes that are selected.
		for selected_node in gizmo.node._selections.keys():
			var item = selection_ui.create_item(gizmo_root)
			item.set_text(0, selected_node.get_meta("pretty_name"))
			item.set_selectable(0, false)

	return


func _set_active_gizmo(gizmo_id: int) -> void:
	for gizmo in gizmos:
		if gizmo.id == gizmo_id:
			# Set the target gizmo to on.
			_set_gizmo_render_state(gizmo.node, true)
			continue
		# Turn off all gizmos.
		_set_gizmo_render_state(gizmo.node, false)
	return


func _toggle_gizmos(state: bool = false) -> void:
	for gizmo in gizmos:
		var _node = gizmo.node
		_node.show_selection_box = state
		_node.mode = 0 if state == false else _node.ToolMode.SCALE | _node.ToolMode.MOVE | _node.ToolMode.ROTATE
	return


func _set_gizmo_render_state(gizmo: Node, state: bool = false) -> void:
	gizmo.show_selection_box = state
	gizmo.mode = 0 if state == false else gizmo.ToolMode.SCALE | gizmo.ToolMode.MOVE | gizmo.ToolMode.ROTATE
	return


func _gizmo_new(node_id: int) -> void:
	var target_node = spawnable_m.get_by_id(node_id)
	var gizmo_schema_index = NSB.get_node_index("Gizmo")
	var gizmo_node: Node

	if target_node == { }:
		GlobalLogger.log("Tried to add a gizmo to an invalid node.", Enum.LogLevel.WARNING)
		return

	gizmo_node = await spawnable_m.create(gizmo_schema_index)

	gizmos.append({ "node": gizmo_node, "id": int(gizmo_node.name) })

	gizmo_node.transform_changed.connect(func(mode, value): _transform_gizmo(mode, value, gizmo_node._selections))

	gizmo_node.select(target_node.node)
	_set_active_gizmo(int(gizmo_node.name))
	_update_selection_ui()
	return


func _gizmo_add(gizmo_id: int, node_id: int) -> void:
	var gizmo = spawnable_m.get_by_id(gizmo_id)
	var target_node = spawnable_m.get_by_id(node_id)

	# Check if we are selecting a child of a selected node.
	for selected_node in gizmo.node._selections:
		if selected_node.is_ancestor_of(target_node.node):
			_gizmo_new(target_node.id)
			return

	# Check if we are selecting a parent of a selected node.
	for selected_node in gizmo.node._selections.keys():
		if target_node.node.is_ancestor_of(selected_node):
			gizmo.node.deselect(selected_node)

	gizmo.node.select(target_node.node)
	_update_selection_ui()
	return


func _gizmo_remove(gizmo_id: int, node_id: int) -> void:
	var gizmo = spawnable_m.get_by_id(gizmo_id)
	var target_node = spawnable_m.get_by_id(node_id)
	gizmo.node.deselect(target_node.node)
	_update_selection_ui()
	return


func _gizmo_delete(node_id: int) -> void:
	var gizmo_index = gizmos.find_custom(func(entry): return entry.id == node_id)
	gizmos.remove_at(gizmo_index)

	await spawnable_m.destroy(node_id)
	_update_selection_ui()
	return


func _transform_gizmo(_mode: int, _value: Vector3, nodes: Dictionary) -> void:
	for node_to_move in nodes:
		spawnable_m.position_spawnable.rpc(int(node_to_move.name), node_to_move.position, node_to_move.rotation, node_to_move.scale)
