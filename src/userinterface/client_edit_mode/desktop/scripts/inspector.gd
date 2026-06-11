extends Node

var _clicked_item: TreeItem = null

@onready var tree_view: Tree = get_node("MarginContainer/HBoxContainer/Container/VBoxContainer/MarginContainer/Tree")
@onready var scene_m = get_tree().current_scene.get_node("SceneManager")
@onready var spawnable_m: Node
@onready var session_signalbus: Node
@onready var popup_menu = $PopupMenu
@onready var session_root: Node


func _ready() -> void:
	_build_add_node_popup()

	# Instance signals
	Events.dash_session_changed.connect(_session_changed)

	tree_view.item_mouse_selected.connect(_on_tree_item_mouse_selected)
	popup_menu.id_pressed.connect(_on_popup_menu_id_pressed)

	popup_menu.hide()
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
	for i in popup_menu.item_count:
		popup_menu.remove_item(0)
	popup_menu.add_item("Add Child", 0)
	popup_menu.add_item("Remove Node", 1)
	popup_menu.add_item("Select", 2)
	return


func _session_changed():
	session_root = scene_m.get_master_root(scene_m.active_session)
	spawnable_m = scene_m.get_master_scene(scene_m.active_session).get_node("SpawnableManager")
	session_signalbus = scene_m.get_master_scene(scene_m.active_session).get_node("SignalBus")

	if session_signalbus.is_connected("node_created", populate_tree_from_node) == false:
		session_signalbus.node_created.connect(populate_tree_from_node)
		session_signalbus.node_destroyed.connect(populate_tree_from_node)
	populate_tree_from_node()


func _on_tree_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int):
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		_clicked_item = tree_view.get_item_at_position(mouse_position)

		if _clicked_item:
			var global_pos = tree_view.get_global_mouse_position()
			popupmenu_populate_generic()
			popup_menu.position = global_pos
			popup_menu.popup()


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
	_select_node_with_gizmo(entity)

	return


func _on_popup_menu_id_pressed(id: int):
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
				await spawnable_m.destroy(int(_name))
			2:
				_select_node_with_gizmo(node)


func _select_node_with_gizmo(node: Node) -> void:
	var the_root = scene_m.get_master_root(scene_m.active_session)
	var schema_index = NSB.get_node_index("Gizmo")
	var gizmo = await spawnable_m.create(schema_index, int(node.name))

	gizmo.set_meta("scene_node", true)
	gizmo.set_meta("pretty_name", "Gizmo")
	the_root.add_child(gizmo)
	gizmo.transform_changed.connect(func(mode, value): _transform_gizmo(mode, value, gizmo._selections))

	gizmo.clear_selection()
	gizmo.select(node)

	return


func _transform_gizmo(_mode: int, _value: Vector3, nodes: Dictionary) -> void:
	for node_to_move in nodes:
		spawnable_m.position_spawnable.rpc(int(node_to_move.name), node_to_move.position, node_to_move.rotation, node_to_move.scale)
