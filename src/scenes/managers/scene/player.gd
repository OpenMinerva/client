# --- License
# File: /client/src/scenes/managers/scene/player.gd
# Project: OpenMinerva
# Created Date: 13 April 2026
# Copyright (c) 2026 OpenMinerva Contributors
# License: MIT License
# --- License
extends Node

@onready var registry: Node = get_node("Registry")
@onready var session_master_node: Node3D = get_parent()
@onready var _sess_spawnable_m: Node = session_master_node.get_manager(session_master_node.MANAGER_TYPE.SPAWNABLE)


@rpc("call_local", "authority", "reliable")
func add_player(peer_id: int) -> void:
	var caller_id: int = multiplayer.get_remote_sender_id()

	GlobalLogger.log("[%s] Adding peer '%s' to the player list" % [caller_id, peer_id])
	registry.add_player(peer_id, -1)
	return


func set_player_database(database: Dictionary) -> void:
	registry.clear_registry()
	for _player_id in database.keys():
		var _entry: Dictionary = database[_player_id]
		var _db_entry: Dictionary = _sess_spawnable_m.get_by_id(int(_entry.node_id))
		_entry.node = _db_entry.node
		registry.add_player(int(_player_id), int(_entry.node_id))

	return


@rpc("call_local", "authority", "reliable")
func remove_player(peer_id: int) -> void:
	var caller_id: int = multiplayer.get_remote_sender_id()
	var _player: Dictionary = registry.get_player(peer_id)

	GlobalLogger.log("[%s] Removing peer '%s' from the player list" % [caller_id, peer_id])
	if _player != { }:
		_sess_spawnable_m.destroy_spawnable(int(_player.node.name))

	registry.remove_player(peer_id)
	return


@rpc("call_local", "authority", "reliable")
func set_player_node(peer_id: int, node_id: int) -> void:
	var _target = registry.get_player(peer_id)

	# TODO: Error warnings
	if _target == { }:
		return

	var _node: Node = _sess_spawnable_m.get_by_id(node_id)

	if _node == null:
		return

	_target.node = _node
	_target.node_id = _node.name

	# If this is our own player node being set, ensure we have authority
	if peer_id == multiplayer.get_unique_id():
		if _node and _node.has_method("set_multiplayer_authority"):
			_node.set_multiplayer_authority(peer_id)
			# HACK: Force set the camera to active.
			_node._node_camera.current = true
	return


func kill_player() -> void:
	GlobalLogger.log("'%s' is not implemented." % get_stack()[0]["function"], Enum.LogLevel.WARNING)
	return


func get_player_count() -> int:
	return registry.get_all_players().size()
