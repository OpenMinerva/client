# --- License
# File: /client/src/scenes/manager/scene/spawnable_manager_spawnables.gd
# Project: OpenMinerva
# Created Date: 02 September 2026
# Copyright (c) 2026 OpenMinerva Contributors
# License: MIT License
# --- License
extends Node

@onready var _registry = get_node("../Registry")


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
		_parent_node = { "node": get_parent().get_parent().get_node("root") }

	_node = NSB.build(node_type)

	var _db_id = _registry.add_spawnable(_node, node_type, spawner_peer_id, node_id)

	_node.name = str(_db_id)

	# HACK: Spawn the node at origin.
	if _node.get("position") != null:
		_node.position = Vector3(0, 0, 0)

	_parent_node.node.add_child(_node)

	return _node


func destroy() -> Node:
	return
