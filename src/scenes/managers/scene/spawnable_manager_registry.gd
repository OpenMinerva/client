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

@onready var _id: int = 1
@onready var _spawnables: Array[Dictionary] = []
@onready var _assets: Array[Dictionary] = []
@onready var _asset_relations: Array[Dictionary] = []
@onready var _gizmos: Array[Dictionary] = []


func add_spawnable(node: Node, type: String, spawner_peer_id: int, node_id: int = _id) -> int:
	GlobalLogger.log("Adding spawnable '%s' to database." % node.name)
	var _db_entry = SPAWNABLE_TEMPLATE.duplicate()

	_db_entry.id = node_id
	_db_entry.node = node
	_db_entry.type = type
	_db_entry.spawner = spawner_peer_id

	_spawnables.append(_db_entry)

	_id = _id + 1

	GlobalLogger.log("Spawnable '%s' successfully added to database as id '%s'." % [node.name, _db_entry.id])
	return _db_entry.id


func get_spawnable(node_id: int) -> Dictionary:
	# GlobalLogger.log("Getting spawnable '%s' from database." % node_id)
	var _db_index: int = _spawnables.find_custom(func(entry): return entry.id == node_id)

	if _db_index == -1:
		GlobalLogger.log("Could not find spawnable '%s' in database." % node_id, Enum.LogLevel.INFO)
		return { }

	var _db_entry: Dictionary = _spawnables[_db_index]

	return _spawnables[_db_index]


func remove_spawnable(node_id: int) -> void:
	GlobalLogger.log("Removing spawnable '%s' from database." % node_id)
	var _db_index: int = _spawnables.find_custom(func(entry): return entry.id == node_id)

	if _db_index != -1:
		_spawnables.remove_at(_db_index)
		GlobalLogger.log("Spawnable '%s' removed from database." % node_id)
	return


func get_all_spawnable() -> Array[Dictionary]:
	return _spawnables


func get_active_id() -> int:
	GlobalLogger.log("Deprecated call '%s'" % get_stack()[0]["function"], Enum.LogLevel.WARNING)
	return _id


func add_asset(asset_class: String, resource: Resource, properties: Array, asset_id: int = _id) -> int:
	GlobalLogger.log("Adding asset '%s' to database." % asset_id)

	var _db_entry = ASSET_TEMPLATE.duplicate()
	_db_entry.id = asset_id
	_db_entry.resource = resource
	_db_entry.props = properties
	_db_entry.asset_class = asset_class

	_assets.append(_db_entry)

	_id = _id + 1

	return _db_entry.id


func get_asset(asset_id: int) -> Dictionary:
	GlobalLogger.log("Getting asset '%s' from database." % asset_id)
	var _db_index: int = _assets.find_custom(func(entry): return entry.id == asset_id)

	if _db_index == -1:
		GlobalLogger.log("Could not find asset '%s' in database." % asset_id, Enum.LogLevel.WARNING)
		return { }

	var _db_entry: Dictionary = _assets[_db_index]

	return _assets[_db_index]


func remove_asset() -> void:
	# GlobalLogger.log("Removing asset '%s' from database."%)
	return


func get_all_asset() -> Array[Dictionary]:
	return _assets


func add_relation(node_id: int, node_property: String, resourece_id: int) -> void:
	GlobalLogger.log("Adding asset relation between '%s' and '%s' to database." % [node_id, resourece_id])

	var _db_entry = ASSET_RELATION_TEMPLATE.duplicate()
	_db_entry.node_id = node_id
	_db_entry.node_property = node_property
	_db_entry.resource_id = resourece_id

	_asset_relations.append(_db_entry)

	_id = _id + 1

	return


func get_relation() -> Dictionary:
	# GlobalLogger.log("Getting asset relation '%s' from database."%)
	return { }


func remove_relation() -> void:
	return


func get_all_asset_relation() -> Array[Dictionary]:
	return _asset_relations
