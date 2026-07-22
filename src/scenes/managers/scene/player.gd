# --- License
# File: /client/src/scenes/managers/scene/player.gd
# Project: OpenMinerva
# Created Date: 13 April 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Node

@onready var spawnable_m = get_node("../SpawnableManager")

const PLAYER_TEMPLATE = {
	"peer_id": 0,
	"node_id": -1,
	"node": null,
}

var module_active: bool = false
var players = { }


@rpc("authority", "reliable")
func add_player(peer_id: int) -> void:
	var caller_id = multiplayer.get_remote_sender_id()
	var database_template = PLAYER_TEMPLATE.duplicate()

	GlobalLogger.log("[%s] Adding peer '%s' to the player list" % [caller_id, peer_id])
	database_template.set("peer_id", peer_id)
	players.set(str(peer_id), database_template)
	return

func set_player_database(database: Dictionary) -> void:
	players = database

	# Fix the database references
	for _player in players.keys():
		var _entry = players[_player]
		var _db_entry = spawnable_m.get_by_id(int(_entry.node_id))
		_entry.node = _db_entry.node

	return

@rpc("authority", "reliable")
func remove_player(peer_id: int) -> void:
	var caller_id = multiplayer.get_remote_sender_id()

	GlobalLogger.log("[%s] Removing peer '%s' from the player list" % [caller_id, peer_id])
	players[str(peer_id)].get("node").queue_free()
	players.erase(str(peer_id))

@rpc("authority", "reliable")
func set_player_node(peer_id: int, node: Node3D) -> void:
	var _target = players[str(peer_id)]

	# TODO: Error warnings
	if _target == null:
		return

	_target.node = node
	_target.node_id = node.name

	# If this is our own player node being set, ensure we have authority
	if peer_id == multiplayer.get_unique_id():
		if node and node.has_method("set_multiplayer_authority"):
			node.set_multiplayer_authority(peer_id)
	return

func kill_player() -> void:
	GlobalLogger.log("'%s' is not implemented." % get_stack()[0]["function"], Enum.LogLevel.WARNING)
	return

func get_player_count() -> int:
	return players.keys().size()
