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
	var spawn_tasks_base_path_table: Dictionary = { }

	var state = loaded_scene.get_state()
	var node_count = state.get_node_count()

	for node_id in range(node_count):
		var node_name = state.get_node_name(node_id)
		var node_path = state.get_node_path(node_id)

		# Spn = "Spawnable" shorthand.
		var spn_type: int = -1
		var spn_transform: Transform3D

		var property_count = state.get_node_property_count(node_id)

		for property_id in range(property_count):
			var _name = state.get_node_property_name(node_id, property_id)
			var _value = state.get_node_property_value(node_id, property_id)

			if _name == "metadata/spawnable_type":
				spn_type = _value
				continue

			if _name == "transform":
				spn_transform = _value
				continue

		spawn_tasks.append({ "task_id": node_id, "spawnable_type": spn_type, "transform": spn_transform, "path": str(node_path), "parent_task": -1 })

	# Order the task list so that based upon the paths of the nodes, each sequential node is guaranteed to have its parent exist.
	spawn_tasks.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return a["path"] < b["path"]
	)

	# From here, we need to get a relationship between a spawn task, and the parent node that will have a given spawn task node as its child.
	for task_id in range(spawn_tasks.size()):
		var _task: Dictionary = spawn_tasks[task_id]
		var _base_dir: String = _task.path.get_base_dir()
		var _parent_task_id: int = -1

		if spawn_tasks_base_path_table.has(_task.path) == false:
			# Add the task id to the table to reference the base path of the node to spawn to this task ID.
			spawn_tasks_base_path_table[_task.path] = task_id

		if _base_dir == "":
			# Special case for the root of the saved spawnable
			# No action
			continue
		else:
			_parent_task_id = spawn_tasks_base_path_table[_task.path.get_base_dir()]
			var _parent_task_index = spawn_tasks.find_custom(func(entry): return entry.task_id == _parent_task_id)
			var _parent_task = spawn_tasks[_parent_task_index]
			spawn_tasks[task_id]["parent_task"] = _parent_task_id

	# Now, with our ordered and relational task queue, start spawning in the nodes.
	for task in spawn_tasks:
		var _parent_task_index = spawn_tasks.find_custom(func(entry): return entry.task_id == task.parent_task)
		var _parent_task = spawn_tasks[_parent_task_index]
		var _node: Node

		if _parent_task_index == -1:
			_node = await session_spawnable_manager.create(task.spawnable_type)
		else:
			_node = await session_spawnable_manager.create(task.spawnable_type, int(_parent_task.node.name))

		task["node"] = _node
		_node.transform = task.transform

	GlobalLogger.log("Loading completed.")
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
