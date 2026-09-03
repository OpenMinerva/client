# --- License
# File: /client/src/scenes/manager/scene/spawnable_manager_spawnables.gd
# Project: OpenMinerva
# Created Date: 02 September 2026
# Copyright (c) 2026 OpenMinerva Contributors
# License: MIT License
# --- License
extends Node

@onready var _registry = get_node("../Registry")
@onready var _session_signalbus: Node = get_node("../../SignalBus")


# Create
@rpc("any_peer", "call_remote", "reliable")
func server_create_spawnable(node_type: String, node_parent: int, forced_node_id: int = -1) -> int:
	var _caller_id: int = _get_caller_id()

	# TODO: Permission check and handling.

	# TODO: Logging (https://github.com/OpenMinerva/client/issues/191)

	var _node_id: int = _registry.get_active_id()

	if forced_node_id != -1:
		_node_id = forced_node_id

	# Validate node_parent, or default to root.
	var _parent = _registry.get_spawnable(node_parent)
	if _parent == { }:
		_parent = { "node": get_node("../../root") }

	var _spawnable: Node = create(node_type, _caller_id, int(_parent.node.name), _node_id)
	create.rpc(node_type, _caller_id, int(_parent.node.name), _node_id)

	# Emit session-wide event.
	_session_signalbus.node_created.emit(_spawnable)

	if is_instance_valid(_spawnable) == false:
		return -1

	return int(_spawnable.name)


@rpc("authority", "reliable")
func create(node_type: String, spawner_peer_id: int, parent: int, node_id: int) -> Node:
	var _node: Node = null
	var _node_schema: Dictionary = NSB.get_entry(node_type)
	var _parent_node: Dictionary = _registry.get_spawnable(parent)

	var _node_exists: bool = _registry.get_spawnable(node_id) != { }
	if _node_exists == true:
		GlobalLogger.log("Tried to spawn in a node that already exists.", Enum.LogLevel.ERROR)
		return null

	var _parent_node_exists: bool = _parent_node != { }
	if _parent_node_exists == false:
		GlobalLogger.log("Could not locate the parent node '%s'. Using root." % parent, Enum.LogLevel.INFO)
		_parent_node = { "node": get_node("../../root") }

	_node = NSB.build(node_type)

	var _db_id: int = _registry.add_spawnable(_node, node_type, spawner_peer_id, node_id)

	_node.name = str(_db_id)

	# HACK: Spawn the node at origin.
	if _node.get("position") != null:
		_node.position = Vector3(0, 0, 0)

	_parent_node.node.add_child(_node)

	get_parent().parent_spawnable(_db_id, parent)
	return _node


# Destroy
@rpc("any_peer", "call_remote", "reliable")
func server_destroy_spawnable(node_id: int) -> void:
	var _caller_id: int = _get_caller_id()

	# TODO: Permissions

	# TODO: Logging (https://github.com/OpenMinerva/client/issues/191)

	var _db_entry = _registry.get_spawnable(node_id)

	if _db_entry == { }:
		GlobalLogger.log("Node '%s' does not exist. Not destroying.")
		return

	var _deletion_queue: Array = _generate_deletion_queue(_db_entry.node)

	for _node in _deletion_queue:
		# TODO: Gizmo removal. Somehow not broken?
		# for _gizmo in get_parent()._gizmos:
		# 	if _node.is_class("Node3D") == true:
		# 		if _gizmo.is_selected(_node):
		# 			get_parent().deselect.rpc(int(_gizmo.name))

		if _node.name.is_valid_int() == false:
			GlobalLogger.log("Node '%s' is malformed." % _db_entry.node.name, Enum.LogLevel.ERROR)
			return

		destroy.rpc(int(_node.name))

	return


@rpc("call_local", "authority", "reliable")
func destroy(node_id: int) -> void:
	var _db_entry = _registry.get_spawnable(node_id)

	if _db_entry == { }:
		GlobalLogger.log("'%s' could not be located in the scene tree." % node_id, Enum.LogLevel.ERROR)
		return

	_session_signalbus.node_destroyed.emit(_db_entry)
	_db_entry.node.queue_free()
	_registry.remove_spawnable(node_id)
	return


# Parenting
func server_parent_spawnable(node_id: int, parent_id: int) -> void:
	var _caller_id: int = _get_caller_id()

	# TODO: Permissions

	# TODO: Logging (https://github.com/OpenMinerva/client/issues/191)

	var _target_db_entry = _registry.get_spawnable(node_id)
	var _parent_db_entry = _registry.get_spawnable(parent_id)

	if _target_db_entry == { }:
		GlobalLogger.log("Failed to find the node: '%s'" % node_id, Enum.LogLevel.WARNING)
		return

	if _parent_db_entry == { }:
		GlobalLogger.log("Failed to find the node to parent to '%s'. Falling back to root." % parent_id, Enum.LogLevel.INFO)

	parent.rpc(node_id, parent_id)

	return


@rpc("call_local", "authority", "reliable")
func parent(node_id: int, parent_id: int) -> void:
	var _target_db_entry = _registry.get_spawnable(node_id)
	var _parent_db_entry = _registry.get_spawnable(parent_id)

	if _parent_db_entry == { }:
		# Fallback to root.
		_parent_db_entry = { "node": get_node("../../root") }

	_target_db_entry.node.reparent(_parent_db_entry.node)

	# TODO: Update database
	return


# Local helpers
func _get_caller_id() -> int:
	var _caller_id: int = multiplayer.get_remote_sender_id()
	if _caller_id == 0:
		_caller_id = multiplayer.get_unique_id()

	return _caller_id


func _generate_deletion_queue(base_node: Node) -> Array:
	var result: Array = []
	for child in base_node.get_children():
		result.append_array(_generate_deletion_queue(child))
	result.append(base_node)
	return result
