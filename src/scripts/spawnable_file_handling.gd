# --- License
# File: /client/src/scripts/spawnable_file_handling.gd
# Project: OpenMinerva
# Created Date: 16 June 2026
# Copyright (c) 2026 OpenMinerva Contributors
# License: MIT License
# --- License
extends Node

const RESOURCE_REFERENCE_TEMPLATE: Dictionary = {
	"resource": null,
	"spawnable_id": -1,
}
const RESOURCE_RELATION_TEMPLATE: Dictionary = {
	"target": -1,
	"field": "",
	"value": -1,
}

@onready var app_scene_m: Node = get_tree().root.find_child("AppSceneManager", true, false)


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

	# This duplicate does not touch the scene tree.
	root = root.duplicate()

	var original_owners = _get_node_ownership(root)
	_set_temporary_ownership_recursive(root, root)

	_remove_invalid_nodes(root)

	var packed_scene = _create_packed_scene(root)
	var _data_hash: String = var_to_str(packed_scene).sha256_text()

	_externalize_assets(root, _data_hash)

	var file_path = StateManager.get_spawnable_path_string() + _data_hash + ".tscn"
	ResourceSaver.save(packed_scene, file_path)

	# Add spawnable to the database.
	var _database_row: Dictionary = {
		"hash": _data_hash,
		"name": _spawnable_name,
		"directory": file_path,
		"creation_date": int(Time.get_unix_time_from_system()),
		"type": type,
	}
	Database.set_spawnable(_data_hash, _database_row)

	Events.cem_spawnable_saved.emit()

	# I have no idea what ownership is in terms of nodes are right now, so put it back as to not break anything
	_restore_ownership(root, original_owners)

	return


func load_spawnable(path: String) -> Node:
	var _session_master_node: Node3D = app_scene_m.get_session_master(app_scene_m.active_session)
	var _sess_spawnable_m = _session_master_node.get_manager(_session_master_node.MANAGER_TYPE.SPAWNABLE)
	var _tasks: Array[Dictionary] = []
	var _path_parent_dictionary: Dictionary = { }

	var _shaders: Dictionary = { }

	# Temporary variable to store the resources used in the base properties of a node.
	var _scene_node_resources: Array = []

	# Long-term storage of all resources used in the scene.
	var _scene_resources: Dictionary = { }

	# Contains the map to associate resources with property values.
	var _scene_resource_association: Array[Dictionary] = []

	# Contains the map of resources that are a property of another resource.
	var _scene_resource_relations: Array[Dictionary] = []

	# Check if file exists at the given path.
	if FileManager.file_exists(path) == false:
		GlobalLogger.log("File '%s' does not exist." % path, Enum.LogLevel.INFO)
		return null

	var _scene: PackedScene = ResourceLoader.load(path)
	var _state: SceneState = _scene.get_state()
	var _num_nodes_in_state: int = _state.get_node_count()

	# Generate the list of tasks we need to preform as well as include the information about the node.
	for _node_id in range(_num_nodes_in_state):
		var _num_properties: int = _state.get_node_property_count(_node_id)
		var _node_path: String = _state.get_node_path(_node_id)
		var _node_type: String = _state.get_node_type(_node_id)
		var _task: Dictionary = { }

		# Build the tasks dictionary that is used for
		_task.id = _node_id
		_task.parent = -1
		_task.path = _node_path
		_task.metadata = []
		_task.properties = []

		_task.metadata.append({ "name": "spawnable_type", "value": _node_type })

		# For each of the properties in a given node in the scene state.
		for _prop_id in range(_num_properties):
			var _prop_name: String = _state.get_node_property_name(_node_id, _prop_id)
			var _prop_value: Variant = _state.get_node_property_value(_node_id, _prop_id)

			# If the property value of a node is a resource, we need to have special handing for this.
			# We have to spawn in resources separately so they are networked.
			if _prop_value is Resource:
				var _association_entry: Dictionary = RESOURCE_RELATION_TEMPLATE.duplicate()
				_association_entry.target = _node_id
				_association_entry.field = _prop_name
				_association_entry.value = _prop_value.get_instance_id()
				_scene_resource_association.append(_association_entry)

				_scene_node_resources.append(_prop_value)

			# If the property is metadata, add it as a property.
			# TODO: Why do I separate this? Surely if it is metadata, I can just add it as a property again because it is (or I think it is) a property.
			if _prop_name.begins_with("metadata/") == true:
				if _prop_name.contains("spawnable_type") == true:
					# HACK:Ignore existing spawnable type metadata.
					continue

				_task.metadata.append({ "name": _prop_name.replace("metadata/", ""), "value": _prop_value })
				continue

			# If the property is an actual property, add it to the properties list.
			if typeof(_prop_name) != TYPE_STRING_NAME && _prop_name.begins_with("metadata/") == false:
				_task.properties.append({ "name": _prop_name, "value": _prop_value })
				continue

			# FIXME: Why do I set this in the root of the dictionary? Pretty sure this would cause issues somewhere else.
			# Though right now this seems to be unreachable due to the other checks effectively capturing all cases.
			_task.set(_prop_name, _prop_value)

		_tasks.append(_task)

	# Build the dictionary that is used to keep track of all resources to spawn in.
	_scene_resources = _build_resource_reference_dictionary(_scene_node_resources, _scene_resource_relations)

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

	# Create the resources in the scene.
	for _resource_dictionary_key in _scene_resources:
		var _resource_entry: Dictionary = _scene_resources[_resource_dictionary_key]
		var _resource_value: Resource = _resource_entry.resource
		var _flat_resource: Dictionary = _flatten_resource(_resource_value)
		var _resource: Resource = await _sess_spawnable_m.create_resource(_flat_resource.class, _flat_resource.properties)
		_scene_resources[_resource_dictionary_key].resource = _resource

	# After creating the resources, if any of these resources have a sub-resource as a value for the properties, add the relation.
	for _relation in _scene_resource_relations:
		if _scene_resources.has(_relation.target) == false || _scene_resources.has(_relation.value) == false:
			continue

		var _parent_resource: Resource = _scene_resources[_relation.target].resource
		var _sub_resource: Resource = _scene_resources[_relation.value].resource

		_sess_spawnable_m.set_property(int(_parent_resource.get_name()), _relation.field, _sub_resource)

	# Spawn the nodes into the scene.
	_tasks = await _spawn_nodes(_sess_spawnable_m, _tasks)

	# Add resources to the nodes as properties.
	# TODO: How does this differ from setting the nodes as properties?
	for _association in _scene_resource_association:
		var _task_reference_index: int = _tasks.find_custom(func(entry): return entry.id == _association.target)
		var _task_reference: Dictionary = _tasks[_task_reference_index]
		var _spawnable_resource: Resource = _scene_resources[_association.value].resource
		_sess_spawnable_m.set_resource(int(_task_reference.node.name), _association.field, int(_spawnable_resource.get_name()))

	# Return the parent of the spawned spawnable scene.
	var _parent_task_index: int = _tasks.find_custom(func(entry): return entry.id == 0)
	var _parent_task = _tasks[_parent_task_index]
	var _parent_node: Node = _parent_task.node
	return _parent_node


# Helper functions for saving an loading spawnables.
## Parse through all tasks provided by load_spawnable and instantiate all nodes into the scene.
func _spawn_nodes(spawnable_manager: Node, task_list: Array[Dictionary]) -> Array[Dictionary]:
	for _task in task_list:
		var _node: Node

		# If there is no parent to this node.
		if _task.parent == -1:
			# If there is not a spawnable type for this node.
			# TODO: I want to remake the spawning system, so at some point this check will no longer be strictly necessary. Probably anyways.
			if _task.has("metadata/spawnable_type") == false:
				# Fallback to generic Node3D
				GlobalLogger.log("Spawnable type not defined. Using Node3D.", Enum.LogLevel.WARNING)
				_task["metadata/spawnable_type"] = "Node3D"

			# This spawnable has a type defined. Create a new spawnable with that spawnable type.
			_node = await spawnable_manager.create_spawnable(_task["metadata/spawnable_type"])
		else:
			# This spawnable is a child of another spawnable. Find the parent...
			var _parent_task_index_id: int = task_list.find_custom(func(_entry): return _entry.id == _task.parent)
			var _parent_task: Dictionary = task_list[_parent_task_index_id]

			# Get the spawnable type of the spawnable we intend on spawning.
			var _spawnable_type_index: int = _task.metadata.find_custom(func(entry): return entry.name == "spawnable_type")
			var _spawnable_type: String = _task.metadata[_spawnable_type_index].value

			# Create the spawnable.
			_node = await spawnable_manager.create_spawnable(_spawnable_type, int(_parent_task.node.name))

		# The Spawnable now exists in the scene. Add the spawnable to our dictionary.
		_task.node = _node

		# If we can transform the spawnable, update the transform.
		if _task.has("transform") == true:
			spawnable_manager.transform_spawnable(int(_task.node.name), _task.transform)

		# For all of the defined metadata of the spawnable, update the metadata of the spawnable.
		# TODO: This is identical to the properties setter. Why did I separate these two again? Maybe it was legacy code carried over?
		for _prop in _task.metadata:
			spawnable_manager.set_property(int(_node.name), _prop.name, _prop.value)

		# For all of the defined properties of the spawnable, update the properties of the spawnable.
		for _prop in _task.properties:
			spawnable_manager.set_property(int(_task.node.name), _prop.name, _prop.value)

	# We made some changes to the task list including adding references to the created nodes in the dictionary.
	# Return the updated object so that we can update the task list in the load_spawnable function.
	return task_list


func _add_spawnable_asset_relation(spawnable_hash: String, asset_hash: String) -> void:
	Database.set_spawnable_asset_rel(spawnable_hash, asset_hash)
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


func _build_resource_reference_dictionary(flat_resource_array: Array, resource_relations: Array[Dictionary]) -> Dictionary:
	var _return_data: Dictionary = { }
	var _index_of_array: int = 0

	while _index_of_array < flat_resource_array.size():
		var _resource: Resource = flat_resource_array[_index_of_array]
		var _resource_id: int = _resource.get_instance_id()
		var _resource_registry_entry: Dictionary = RESOURCE_REFERENCE_TEMPLATE.duplicate()
		var _resource_properties: Array[Dictionary] = _resource.get_property_list()

		_resource_registry_entry.resource = _resource
		_return_data[_resource_id] = _resource_registry_entry

		for _property in _resource_properties:
			var _target_property_name: String = _property.name
			var _target_property_value: Variant = _resource.get(_target_property_name)

			if _target_property_value is Resource:
				# Add relation to property of parent _resource to this resource.
				var _relation_entry: Dictionary = RESOURCE_RELATION_TEMPLATE.duplicate()
				_relation_entry.target = _resource_id
				_relation_entry.field = _target_property_name
				_relation_entry.value = _target_property_value.get_instance_id()
				resource_relations.append(_relation_entry)

				if _return_data.has(_target_property_value.get_instance_id()) == false:
					flat_resource_array.append(_target_property_value)

		_index_of_array = _index_of_array + 1

	return _return_data


func _externalize_assets(root: Node, spawnable_hash: String) -> Node:
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
				var _file = FileManager.open(_external_path)
				_data_size = _file.get_length()
				_file.close()

				var _database_row: Dictionary = {
					"hash": _data_hash,
					"directory": _external_path,
					"size": _data_size,
				}
				Database.set_asset(_data_hash, _database_row)

			_add_spawnable_asset_relation(spawnable_hash, _data_hash)

	for child in root.get_children():
		_externalize_assets(child, spawnable_hash)

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
