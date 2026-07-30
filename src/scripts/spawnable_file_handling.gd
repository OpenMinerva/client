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
	# FIXME: When saving the node scene, The FileManager should be used entirely.
	# ResourceLoader / ResourceSaver should not be called from here.
	var original_owners = _get_node_ownership(root)
	_set_temporary_ownership_recursive(root, root)

	_externalize_assets(root)

	var packed_scene = _create_packed_scene(root)
	var file_path = FileManager._current_path() + "/" + root.get_meta("pretty_name", "NO_NAME") + ".tscn"
	ResourceSaver.save(packed_scene, file_path)

	# I have no idea what ownership is in terms of nodes are right now, so put it back as to not break anything
	_restore_ownership(root, original_owners)

	return


func load_spawnable(path: String) -> void:
	var session_spawnable_manager = scene_m.get_master_scene(scene_m.active_session).get_node("SpawnableManager")
	var _tasks: Array[Dictionary] = []
	var _path_parent_dictionary: Dictionary = { }

	# TODO: Check to see if path exists.

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
			# TODO: Is this correct form to parent the node to the correct node?
			var _parent_task_index_id: int = _tasks.find_custom(func(_entry): return _entry.id == _task.parent)
			var _parent_task: Dictionary = _tasks[_parent_task_index_id]
			_node = await session_spawnable_manager.create(_task["metadata/spawnable_type"], int(_parent_task.node.name))

		_task.node = _node

		if _task.has("transform") == true:
			session_spawnable_manager.set_transform(int(_task.node.name), _task.transform)

		for _prop in _task.properties:
			var _prop_dict = _task[_prop]
			# TODO: I need to have some kind of way to have a reference to a specific resource by name / id, create that resource, and associate that generated id with the generated resource.

			# First we should create the asset on the server
			var _asset: Resource = await session_spawnable_manager.create_asset(_prop_dict.class, _prop_dict.properties)

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
	for property in root.get_property_list():
		var value = root.get(property.name)

		if value is Resource and value.resource_path.is_empty():
			# TODO: Hash the files to use as names?
			var external_path = "user://spawnables_assets/%d.res" % randi()
			ResourceSaver.save(value, external_path)

			var external_resource = load(external_path)
			external_resource.take_over_path(external_path)

			root.set(property.name, external_resource)

	for child in root.get_children():
		_externalize_assets(child)

	return root


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
