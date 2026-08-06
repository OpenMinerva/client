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


func save_spawnable(root: Node, type: Enum.SpawnableType = Enum.SpawnableType.ITEM, name_override: String = "") -> void:
	# Take a node path from the scene, and save that node to the file
	# In order to save nodes using the ResourceSaver, we need to make all nodes that are a child of the root have the owner of the root.
	# FIXME: When saving the node scene, The FileManager should be used entirely.
	# ResourceLoader / ResourceSaver should not be called from here.
	var _spawnable_name: String = ""

	# TODO: Get hash of file, and use that hash for filename on disk.
	if name_override != "":
		_spawnable_name = name_override
	elif root.has_meta("pretty_name") == true:
		_spawnable_name = root.get_meta("pretty_name")
	else:
		_spawnable_name = "Untitled"

	# Duplicate the node, this is so we can make modifications to it (if required to)
	# This duplicate does not touch the scene tree.
	root = root.duplicate()

	var original_owners = _get_node_ownership(root)
	_set_temporary_ownership_recursive(root, root)

	# Externalize assets makes it so that networking things are consistent.
	_externalize_assets(root)

	# Remove nodes that should not be saved.
	_remove_invalid_nodes(root)

	var packed_scene = _create_packed_scene(root)
	var _data_hash: String = var_to_str(packed_scene).sha256_text()
	var file_path = FileManager._current_path() + _data_hash + ".tscn"
	ResourceSaver.save(packed_scene, file_path)

	# Add spawnable to the database.
	var _database_row: Dictionary = {
		"hash": _data_hash,
		"name": _spawnable_name,
		"directory": file_path,
		"original_owner": "",
		"creation_date": -1,
		"modified_date": -1,
		"type": type,
	}
	Database.set_spawnable(_data_hash, _database_row)

	# I have no idea what ownership is in terms of nodes are right now, so put it back as to not break anything
	_restore_ownership(root, original_owners)

	return


func load_spawnable(path: String) -> void:
	var session_spawnable_manager = scene_m.get_master_scene(scene_m.active_session).get_node("SpawnableManager")
	var _tasks: Array[Dictionary] = []
	var _path_parent_dictionary: Dictionary = { }

	# Check if file exists at the given path.
	if FileAccess.file_exists(path) == false:
		GlobalLogger.log("File '%s' does not exist." % path, Enum.LogLevel.INFO)
		return

	var _scene = ResourceLoader.load(path)
	var _state = _scene.get_state()
	var _num_nodes_in_state: int = _state.get_node_count()

	# Generate the list of tasks we need to preform as well as include the information about the node.
	for _node_id in range(_num_nodes_in_state):
		var _num_properties: int = _state.get_node_property_count(_node_id)
		var _node_path: String = _state.get_node_path(_node_id)
		var _task: Dictionary = { }

		_task.id = _node_id
		_task.parent = -1
		_task.path = _node_path
		_task.properties = [] # An array listing the keys of property fields.

		for _prop_id in range(_num_properties):
			var _prop_name: String = _state.get_node_property_name(_node_id, _prop_id)
			var _prop_value: Variant = _state.get_node_property_value(_node_id, _prop_id)

			if _prop_value is Resource:
				_task.properties.append(_prop_name)
				_prop_value = _flatten_resource(_prop_value)

			_task.set(_prop_name, _prop_value)

		_tasks.append(_task)

	# Sort the tasks array using the paths field, the array should be in such an order that the parent of a node is always at a lower index in the array. Meaning when its time for a given node to spawn, the parent already exists.
	_tasks.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["path"] < b["path"])

	# Now we add the correct "parent" value to the tasks, so that we can be sure that the nodes are spawned in such an order that the nodes parent exists before it does.
	for _task_from_queue in range(_tasks.size()):
		var _task: Dictionary = _tasks[_task_from_queue]
		var _task_base_path: String = _task.path.get_base_dir()
		var _parent_task_id: int = -1

		if _path_parent_dictionary.has(_task.path) == false:
			# We do not have a listing for this node in the dictionary keeping track of parents. Any node that is a child of this one won't know where this node is.
			_path_parent_dictionary[_task.path] = _task.id

		if _task_base_path == "":
			# Special case for the root of a spawnable. Do nothing.
			continue

		# Set the parent task of this task based upon previously discovered values.
		_task.parent = _path_parent_dictionary[_task_base_path]

	# Finally, we spawn in the nodes.
	for _task in _tasks:
		var _node: Node
		if _task.parent == -1:
			if _task.has("metadata/spawnable_type") == false:
				# HACK: Force unknown spawnable types to be Node3D (Empty).
				GlobalLogger.log("Spawnable type not defined. Using Node3D.", Enum.LogLevel.WARNING)
				_task["metadata/spawnable_type"] = "Node3D"

			_node = await session_spawnable_manager.create(_task["metadata/spawnable_type"])
		else:
			var _parent_task_index_id: int = _tasks.find_custom(func(_entry): return _entry.id == _task.parent)
			var _parent_task: Dictionary = _tasks[_parent_task_index_id]
			_node = await session_spawnable_manager.create(_task["metadata/spawnable_type"], int(_parent_task.node.name))

		_task.node = _node

		if _task.has("transform") == true:
			session_spawnable_manager.set_transform(int(_task.node.name), _task.transform)

		for _prop in _task.properties:
			var _prop_dict = _task[_prop]

			# First we should create the asset on the server
			var _asset: Resource = await session_spawnable_manager.create_asset(_prop_dict.class, _prop_dict.properties)

			# Then we set that resource as the value of the resource property.
			session_spawnable_manager.set_resource(int(_task.node.name), _prop, int(_asset.get_name()))

	return


func _flatten_resource(resource: Resource):
	var _resource_props = resource.get_property_list()
	var _response: Dictionary = { "properties": [], "class": "" }

	_response.class = resource.get_class()
	for resource_id in range(_resource_props.size()):
		var _name = _resource_props[resource_id].name
		var _value = resource.get(_name)

		_response.properties.append({ "name": _name, "value": _value })

	return _response


func _externalize_assets(root: Node) -> Node:
	# TODO: This way of externalizing assets functions, but is not what is intended. I need to create a thorough walk-through of a node hierarchy and individually get all resources of that node. Right now this seems to just do a surface level extraction.
	for property in root.get_property_list():
		var value = root.get(property.name)

		if value is Resource and value.resource_path.is_empty():
			# TODO: Throw this onto a separate thread.
			var _data_hash: String = var_to_str(value).sha256_text()
			var _data_size: int
			var _external_path = "user://spawnables_assets/%s.res" % _data_hash

			ResourceSaver.save(value, _external_path)

			var external_resource = load(_external_path)
			external_resource.take_over_path(_external_path)

			root.set(property.name, external_resource)

			if Database.get_asset(_data_hash) == { }:
				# Add to the database if we do not already have the asset in the database.

				# Get the file size of the asset
				var _file = FileAccess.open(_external_path, FileAccess.READ)
				_data_size = _file.get_length()
				_file.close()

				var _database_row: Dictionary = {
					"hash": _data_hash,
					"directory": _external_path,
					"size": _data_size,
				}
				Database.set_asset(_data_hash, _database_row)

	for child in root.get_children():
		_externalize_assets(child)

	return root


func _remove_invalid_nodes(root: Node) -> Node:
	for _node in root.get_children():
		if _node.get_meta("spawnable_type") == "OM_PlayerController":
			_node.free()
			continue

		if _node.get_meta("spawnable_type") == "Gizmo":
			_node.free()
			continue

		# TODO: Add "persistent" metadata.
		if _node.has_meta("persistent") && _node.get_meta("persistent") == false:
			_node.free()
			continue

		_remove_invalid_nodes(_node)
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


func _set_temporary_ownership_recursive(new_owner: Node, node: Node) -> void:
	node.owner = new_owner
	for child in node.get_children():
		_set_temporary_ownership_recursive(new_owner, child)


func _restore_ownership(_root: Node, _ownership_dict: Dictionary) -> void:
	GlobalLogger.log("'%s' is not implemented." % get_stack()[0]["function"], Enum.LogLevel.WARNING)
	return


func _create_packed_scene(root: Node) -> PackedScene:
	var packed_scene = PackedScene.new()
	packed_scene.pack(root)
	return packed_scene


func _create_pck(_name: String = "") -> PCKPacker:
	var pck_packer = PCKPacker.new()
	pck_packer.pck_start("usr://dev_save.pck")
	return pck_packer
