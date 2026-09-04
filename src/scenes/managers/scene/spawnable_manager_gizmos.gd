# --- License
# File: /client/src/scenes/managers/scene/spawnable_manager_gizmos.gd
# Project: OpenMinerva
# Created Date: 04 September 2026
# Copyright (c) 2026 OpenMinerva Contributors
# License: MIT License
# --- License
extends Node

var _session_gizmos: Dictionary = { }

@onready var _manager = get_parent()
@onready var _registry = get_node("../Registry")
@onready var _spawnables = get_node("../Spawnables")


# Selecting
@rpc("any_peer", "call_remote", "reliable")
func server_select_spawnable(node_id: int) -> int:
	var _caller_id: int = _spawnables._get_caller_id()

	# TODO: Permission check and handling.

	# TODO: Logging (https://github.com/OpenMinerva/client/issues/191)

	if _session_gizmos.has(_caller_id) == true:
		GlobalLogger.log("'%s' had an active gizmo, destroying it." % _caller_id, Enum.LogLevel.INFO)
		await _manager.destroy_spawnable(_session_gizmos[_caller_id])
		_session_gizmos.erase(_caller_id)

	var _gizmo: Node = await _manager.create_spawnable("Gizmo")

	select.rpc(node_id, int(_gizmo.name))

	_session_gizmos[_caller_id] = int(_gizmo.name)
	return int(_gizmo.name)


@rpc("call_local", "authority", "reliable")
func select(node_id: int, gizmo_id: int) -> void:
	# TODO: On gizmo transform, transform spawnable.

	var _node: Node = _registry.get_spawnable(node_id).node
	var _gizmo: Node = _registry.get_spawnable(gizmo_id).node

	if _node.is_class("Node3D"):
		_gizmo.select(_node)
		_gizmo._set_visibility(get_node("../../").visible)
		_gizmo.transform_changed.connect(func(_mode, _value): _manager.transform_spawnable(node_id, _node.transform))

	return


# Deselecting
@rpc("any_peer", "call_remote", "reliable")
func server_deselect_spawnable(gizmo_id: int) -> void:
	var _caller_id: int = _spawnables._get_caller_id()

	# TODO: Permission check and handling.

	# TODO: Logging (https://github.com/OpenMinerva/client/issues/191)

	deselect.rpc(gizmo_id)

	return


@rpc("call_local", "authority", "reliable")
func deselect(gizmo_id: int) -> void:
	var _gizmo: Node = _registry.get_spawnable(gizmo_id).node

	_gizmo.clear_selection()
	return


# Session handling
func show_session_gizmos() -> void:
	# TODO: Session-wide toggle of rendering gizmos. If you are not in edit mode, the gizmos just do not render under any circumstance.
	return


func hide_session_gizmos() -> void:
	# TODO: Session-wide toggle of rendering gizmos. If you are not in edit mode, the gizmos just do not render under any circumstance.
	return
