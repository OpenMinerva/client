# --- License
# File: /client/src/scenes/managers/scene/player_registry.gd
# Project: OpenMinerva
# Created Date: 11 October 2026
# Copyright (c) 2026 OpenMinerva Contributors
# License: MIT License
# --- License
extends Node
## This submodule contains the registry in which players are registered with the client.

## Template for players to store in the _database.
const PLAYER_TEMPLATE: Dictionary = {
	"peer_id": 0,
	"node_id": -1,
	"node": null,
}

## The internal registry to store and keep track of the active and connected players.
var _database: Array[Dictionary] = []


## Clear the registry.
func clear_registry() -> void:
	_database.clear()
	return


## Add a player to the registry.
## [param peer_id] is the ID of the peer.
## [param node_id] is the ID of the spawnable that is controlled by the peer.
func add_player(peer_id: int, node_id: int) -> void:
	var _player: Dictionary = PLAYER_TEMPLATE.duplicate(true)

	_player.peer_id = peer_id
	_player.node_id = node_id

	_database.append(_player)
	return


## Remove a player from our registry.
## [param peer_id] is the ID of the peer to remove.
func remove_player(peer_id: int) -> void:
	GlobalLogger.log("Removing player '%s' from registry." % peer_id)

	var _index: int = _database.find_custom(func(entry): return entry.peer_id == peer_id)
	if _index >= 0:
		_database.remove_at(_index)
		GlobalLogger.log("Player '%s' removed from registry." % peer_id)
		return

	GlobalLogger.log("Player '%s' not found in registry." % peer_id, Enum.LogLevel.WARNING)
	return


## Returns true if we have a player with the given peer_id.
## [param peer_id] is the ID of the peer.
func has_player(peer_id: int) -> bool:
	var _index: int = _database.find_custom(func(entry): return entry.peer_id == peer_id)
	return _index >= 0


## Returns the player information of a player.
## [param peer_id] is the ID of the player to get.
func get_player(peer_id: int) -> Dictionary:
	var _index: int = _database.find_custom(func(entry): return entry.peer_id == peer_id)
	if _index < 0:
		return { }
	return _database[_index]


## Returns all of the connected players.
func get_all_players() -> Array[Dictionary]:
	return _database
