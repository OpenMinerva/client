# --- License
# File: /client/src/scenes/manager/scene/spawnable_manager_registry.gd
# Project: OpenMinerva
# Created Date: 01 September 2026
# Copyright (c) 2026 OpenMinerva Contributors
# License: MIT License
# --- License
extends Node

var _id: int = 1
# New Variables
var _spawnables: Array[Node] = []
var _resources: Array[Resource] = []
var _materials: Array[Material] = []
var _relations: Array[Dictionary] = []
var _gizmos: Array[int] = []


func add_spawnable(node: Node, node_id: int = _id) -> void:
	GlobalLogger.log("Adding spawnable '%s' to database." % node.name)

	node.name = str(node_id)
	_spawnables.append(node)

	if node.has_method("select") == true:
		_gizmos.append(int(node.name))

	GlobalLogger.log("Spawnable '%s' successfully added to database as id '%s'." % [node.name, node_id])
	_id = _id + 1
	return


func get_spawnable(node_id: int) -> Node:
	var _db_index: int = _spawnables.find_custom(func(entry): return int(entry.name) == node_id)

	if _db_index == -1:
		GlobalLogger.log("Could not find spawnable '%s' in database." % node_id, Enum.LogLevel.INFO)
		return null

	return _spawnables[_db_index]


func remove_spawnable(node_id: int) -> void:
	GlobalLogger.log("Removing spawnable '%s' from database." % node_id)
	var _db_index: int = _spawnables.find_custom(func(entry): return int(entry.name) == node_id)

	if _db_index != -1:
		_spawnables.remove_at(_db_index)
		GlobalLogger.log("Spawnable '%s' removed from database." % node_id)

	if _gizmos.has(node_id) == true:
		var _gizmos_db_index: int = _gizmos.find_custom(func(entry): return entry == node_id)
		_gizmos.remove_at(_gizmos_db_index)
	return


func get_all_spawnable() -> Array[Node]:
	return _spawnables


func get_active_id() -> int:
	return _id


func add_asset(resource: Resource, asset_id: int = _id) -> void:
	GlobalLogger.log("Adding asset '%s' to database." % asset_id)

	resource.set_name(str(asset_id))
	_resources.append(resource)

	GlobalLogger.log("Resource '%s' successfully added to database as id '%s'." % [resource.get_name(), asset_id])
	_id = _id + 1
	return


func get_asset(asset_id: int) -> Resource:
	GlobalLogger.log("Getting resource '%s' from database." % asset_id)
	var _db_index: int = _resources.find_custom(func(entry): return int(entry.get_name()) == asset_id)

	if _db_index == -1:
		GlobalLogger.log("Could not find resource '%s' in database." % asset_id, Enum.LogLevel.WARNING)
		return null

	return _resources[_db_index]


func remove_asset() -> void:
	# GlobalLogger.log("Removing asset '%s' from database."%)
	return


func get_all_asset() -> Array[Resource]:
	return _resources


func add_relation(node_id: int, node_property: String, resourece_id: int) -> void:
	GlobalLogger.log("Adding resource relation between '%s' and '%s' to database." % [node_id, resourece_id])

	_relations.append({ "node": node_id, "property": node_property, "value": resourece_id })

	GlobalLogger.log("Relation between '%s' and '%s' added." % [node_id, resourece_id])
	return


func get_relation() -> Dictionary:
	# GlobalLogger.log("Getting asset relation '%s' from database."%)
	return { }


func remove_relation() -> void:
	return


func get_all_asset_relation() -> Array[Dictionary]:
	return _relations


func get_encoded_database() -> Dictionary:
	const ignore_property_name: Array[String] = ["multiplayer", "script", "owner"]
	var _response: Dictionary = { "spawnables": [], "resources": [], "relations": [] }

	for _spawnable in _spawnables:
		var _entry: Dictionary = { "id": -1, "parent": -1, "properties": { }, "metadata": { } }

		_entry.id = str(_spawnable.name)

		if _spawnable.get_parent().name.is_valid_int() == true:
			_entry.parent = int(_spawnable.get_parent().name)

		for _property in _spawnable.get_property_list():
			var _property_value: Variant

			if _property.class_name == "":
				continue

			if ignore_property_name.has(_property.name):
				continue

			_property_value = _spawnable[_property.name]

			if typeof(_property_value) == TYPE_OBJECT:
				if is_instance_of(_property_value, Node) == true:
					_property_value = int(_property_value.name)
				elif is_instance_of(_property_value, Resource) == true:
					_property_value = int(_property_value.get_name())
				else:
					continue

			_entry.properties[_property.name] = _property_value

		for _metadata in _spawnable.get_meta_list():
			_entry.metadata[_metadata] = _spawnable.get_meta(_metadata)

		_response.spawnables.append(_entry)

	for _resource in _resources:
		var _entry: Dictionary = { "id": -1, "properties": { }, "metadata": { } }
		_entry.id = _resource.get_name()

		for _property in _resource.get_property_list():
			var _property_value: Variant

			if _property.name not in _resource:
				continue

			_property_value = _resource[_property.name]

			if typeof(_property_value) == TYPE_OBJECT:
				if is_instance_of(_property_value, Node) == true:
					_property_value = int(_property_value.name)
				elif is_instance_of(_property_value, Resource) == true:
					_property_value = int(_property_value.get_name())
				else:
					continue

			_entry.properties[_property.name] = _property_value

		for _metadata in _resource.get_meta_list():
			_entry.metadata[_metadata] = _resource.get_meta(_metadata)

		_response.resources.append(_entry)

	for _relation in _relations:
		_response.relations.append(_relation)

	return _response
