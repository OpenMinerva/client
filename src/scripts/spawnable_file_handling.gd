# --- License
# File: /client/src/scripts/spawnable_file_handling.gd
# Project: OpenMinerva
# Created Date: 16 June 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Node

@onready var scene_m = get_tree().current_scene.get_node("SceneManager")


func _ready() -> void:
	return


func save_spawnable(root: Node) -> void:
	# Take a node path from the scene, and save that node to the file
	# In order to save nodes using the ResourceSaver, we need to make all nodes that are a child of the root have the owner of the root.
	var original_owners = _get_node_ownership(root)
	_set_temporary_ownership_recursive(root, root)

	var packed_scene = _create_packed_scene(root)
	ResourceSaver.save(packed_scene, "user://dev_save.tscn")

	# I have no idea what ownership is in terms of nodes are right now, so put it back as to not break anything
	_restore_ownership(root, original_owners)

	return


func load_spawnable(scene_node: Node) -> void:
	# For testing, just load it into the current active session
	var session_spawnable_manager = scene_m.get_master_scene(scene_m.active_session).get_node("SpawnableManager")
	var loaded_scene = ResourceLoader.load("user://dev_save.tscn")

	var parent_session_root = scene_m.get_master_root(scene_m.active_session)
	var spawn_tasks: Array[Dictionary] = []
	var task_node_ids: Dictionary = { }

	var state = loaded_scene.get_state()

	var node_count = state.get_node_count()
	for node_id in range(node_count):
		var node_name = state.get_node_name(node_id)
		var node_path = state.get_node_path(node_id)

		var property_count = state.get_node_property_count(node_id)

		var prop_transform: Transform3D
		var prop_node_type = null

		for prop_idx in range(property_count):
			var prop_name = state.get_node_property_name(node_id, prop_idx)
			var prop_value = state.get_node_property_value(node_id, prop_idx)

			# Check if this is your "node_type" metadata entry
			if prop_name == "metadata/spawnable_type":
				prop_node_type = prop_value
				continue

			if prop_name == "transform":
				prop_transform = prop_value
				continue

		# Add the node to the task queue
		spawn_tasks.append({ "task_id": node_id, "spawnable_type": prop_node_type, "transform": prop_transform, "path": str(node_path) })

	# This is to order the tasks in a way that the parent of a node will always appear in front of it.
	spawn_tasks.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return a["path"] < b["path"]
	)

	# Add a direct reference to the parent of each node based upon the "path" key.
	for task_id in range(spawn_tasks.size()):
		var _task_data = spawn_tasks[task_id]
		var _pruned_path = spawn_tasks[task_id].path.get_base_dir()
		if _task_data.path == ".":
			task_node_ids.set(".", 0)
			spawn_tasks[task_id].set("parent_id", -1)
			continue
		task_node_ids.set(_task_data.path, task_node_ids.get(_pruned_path))
		spawn_tasks[task_id].set("parent_id", task_node_ids.get(_pruned_path))

	# Spawn in the nodes from the task list
	for task_id in range(spawn_tasks.size()):
		var _task_data = spawn_tasks[task_id]
		var _parent_index = spawn_tasks.find_custom(func(entry): return entry.task_id == _task_data.parent_id)
		var _parent_node

		if _parent_index == -1:
			_parent_node = parent_session_root
		else:
			var parent_node = spawn_tasks[_parent_index].node
			_parent_node = parent_node

		var _node = await session_spawnable_manager.create(_task_data.spawnable_type, int(_parent_node.name))
		_node.transform = _task_data.transform
		spawn_tasks[task_id].set("node", _node)

	print(spawn_tasks)
	return


func _get_node_ownership(root: Node) -> Dictionary:
	var ownership: Dictionary = { }
	_get_node_ownership_recursive(root, ownership)
	return ownership


func _get_node_ownership_recursive(node: Node, ownership: Dictionary) -> Dictionary:
	if node.owner != null:
		ownership[int(node.name)] = int(node.owner.name)
	else:
		ownership[int(node.name)] = int(-1)

	for child in node.get_children():
		_get_node_ownership_recursive(child, ownership)
	return ownership


func _set_temporary_ownership(root: Node) -> void:
	return


func _set_temporary_ownership_recursive(new_owner: Node, node: Node) -> void:
	node.owner = new_owner
	for child in node.get_children():
		_set_temporary_ownership_recursive(new_owner, child)


func _restore_ownership(root: Node, ownership_dict: Dictionary) -> void:
	return


func _create_packed_scene(root: Node) -> PackedScene:
	var packed_scene = PackedScene.new()
	packed_scene.pack(root)
	return packed_scene


func _create_pck(_name: String = "") -> PCKPacker:
	var pck_packer = PCKPacker.new()
	pck_packer.pck_start("usr://dev_save.pck")
	return pck_packer
