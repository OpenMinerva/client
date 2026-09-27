# --- License
# File: /client/src/scenes/manager/scene/spawnable_manager_registry.gd
# Project: OpenMinerva
# Created Date: 01 September 2026
# Copyright (c) 2026 OpenMinerva Contributors
# License: MIT License
# --- License
extends Node

const SPAWNABLE_TEMPLATE: Dictionary = {
	"type": -1,
	"spawner": -1,
	"physics_owner": 1,
	"node": null,
	"parent": -1,
	"id": -1,
	"pretty_name": "ERROR",
}
const ASSET_TEMPLATE: Dictionary = {
	"id": -1,
	"asset_class": "",
	"properties": { },
}
const ASSET_RELATION_TEMPLATE: Dictionary = {
	"node_id": -1,
	"resource_id": -1,
	"node_property": "",
}

# New Variables
var _spawnables: Array[Node] = []
var _resources: Array[Resource] = []
var _materials: Array[Material] = []
var _relations: Array[Dictionary] = []
var _gizmos: Array[int] = []

@onready var _id: int = 1
@onready var _assets_old: Array[Dictionary] = []
@onready var _asset_rel_old: Array[Dictionary] = []


func add_spawnable(node: Node) -> void:
	GlobalLogger.log("Adding spawnable '%s' to database." % node.name)

	node.name = str(_id)
	_spawnables.append(node)

	if node.has_method("select") == true:
		_gizmos.append(int(node.name))

	GlobalLogger.log("Spawnable '%s' successfully added to database as id '%s'." % [node.name, _id])
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


func add_asset(asset_class: String, resource: Resource, properties: Array, asset_id: int = _id) -> int:
	GlobalLogger.log("Adding asset '%s' to database." % asset_id)

	var _db_entry = ASSET_TEMPLATE.duplicate()
	_db_entry.id = asset_id
	_db_entry.resource = resource
	_db_entry.props = properties
	_db_entry.asset_class = asset_class

	_assets_old.append(_db_entry)

	_id = _id + 1

	return _db_entry.id


func get_asset(asset_id: int) -> Dictionary:
	GlobalLogger.log("Getting asset '%s' from database." % asset_id)
	var _db_index: int = _assets_old.find_custom(func(entry): return entry.id == asset_id)

	if _db_index == -1:
		GlobalLogger.log("Could not find asset '%s' in database." % asset_id, Enum.LogLevel.WARNING)
		return { }

	var _db_entry: Dictionary = _assets_old[_db_index]

	return _assets_old[_db_index]


func remove_asset() -> void:
	# GlobalLogger.log("Removing asset '%s' from database."%)
	return


func update_asset(asset_id: int, key: String, value: Variant) -> void:
	var _db_index: int = _assets_old.find_custom(func(entry): return entry.id == asset_id)

	# TODO: Error handling.

	_assets_old[_db_index][key] = value
	return


func get_all_asset() -> Array[Dictionary]:
	return _assets_old


func add_relation(node_id: int, node_property: String, resourece_id: int) -> void:
	GlobalLogger.log("Adding asset relation between '%s' and '%s' to database." % [node_id, resourece_id])

	var _db_entry = ASSET_RELATION_TEMPLATE.duplicate()
	_db_entry.node_id = node_id
	_db_entry.node_property = node_property
	_db_entry.resource_id = resourece_id

	_asset_rel_old.append(_db_entry)

	_id = _id + 1

	return


func get_relation() -> Dictionary:
	# GlobalLogger.log("Getting asset relation '%s' from database."%)
	return { }


func remove_relation() -> void:
	return


func get_all_asset_relation() -> Array[Dictionary]:
	return _asset_rel_old
