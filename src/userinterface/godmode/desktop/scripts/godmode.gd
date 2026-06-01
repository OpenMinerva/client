extends Node

var _clicked_item: TreeItem = null

@onready var tree_view: Tree = get_node("MarginContainer/HBoxContainer/Container/VBoxContainer/MarginContainer/Tree")
@onready var scene_m = get_tree().current_scene.get_node("SceneManager")
@onready var spawnable_m = scene_m.get_master_scene(scene_m.active_session).get_node("SpawnableManager")
@onready var popup_menu = $PopupMenu


func _ready() -> void:
	var the_root = scene_m.get_master_root(scene_m.active_session)
	populate_tree_from_node(the_root)
	the_root.child_entered_tree.connect(populate_tree_from_node)
	the_root.child_exiting_tree.connect(populate_tree_from_node)

	tree_view.item_mouse_selected.connect(_on_tree_item_mouse_selected)
	popup_menu.id_pressed.connect(_on_popup_menu_id_pressed)

	popup_menu.hide()
	pass


func populate_tree_from_node(_node):
	tree_view.clear()

	var the_root = scene_m.get_master_root(scene_m.active_session)
	var root_node = the_root
	if not root_node:
		return

	var tree_root = tree_view.create_item()

	add_node_to_tree(root_node, tree_root)


# FIXME: The open-ness of the current view is not maintained when refreshing the tree view.
func add_node_to_tree(node: Node, parent_item: TreeItem):
	if node.get_meta("scene_node", false):
		var item = tree_view.create_item(parent_item)

		item.set_text(0, node.get_meta("pretty_name", node.name))
		var class_n = node.get_class()
		var icon_texture = get_class_icon(class_n)
		item.set_icon(0, icon_texture)
		item.set_metadata(0, node)

		for child in node.get_children():
			add_node_to_tree(child, item)


# FIXME: No fail-safe or check to see if icon exists.
func get_class_icon(class_n: String) -> Texture2D:
	return load("res://resources/icons/godot/%s.svg" % class_n)


func popupmenu_populate_generic() -> void:
	for i in popup_menu.item_count:
		popup_menu.remove_item(0)
	popup_menu.add_item("Add Child", 0)
	popup_menu.add_item("Remove Node", 1)
	return


func _on_tree_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int):
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		_clicked_item = tree_view.get_item_at_position(mouse_position)

		if _clicked_item:
			var global_pos = tree_view.get_global_mouse_position()
			popupmenu_populate_generic()
			popup_menu.position = global_pos
			popup_menu.popup()


func _on_popup_menu_id_pressed(id: int):
	if _clicked_item:
		match id:
			0:
				print("Adding child")
				spawnable_m.spawn_spawnable.rpc(1, "", "", _clicked_item.get_metadata(0))
				spawnable_m.spawn_spawnable(1, "", "", _clicked_item.get_metadata(0))
			1:
				print("Removing node")
				_clicked_item.get_metadata(0).queue_free()
