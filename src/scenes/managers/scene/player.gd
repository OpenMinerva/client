# --- License
# File: /client/src/scenes/managers/scene/player.gd
# Project: OpenMinerva
# Created Date: 13 April 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Node

const PLAYER_TEMPLATE = {
	"peer_id": 0,
	"has_spawned": false,
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

	spawn_player(str(peer_id))


@rpc("authority", "reliable")
func remove_player(peer_id: int) -> void:
	var caller_id = multiplayer.get_remote_sender_id()

	GlobalLogger.log("[%s] Removing peer '%s' from the player list" % [caller_id, peer_id])
	players[str(peer_id)].get("node").queue_free()
	players.erase(str(peer_id))


@rpc("authority", "unreliable")
func spawn_player(peer_id: String) -> void:
	var caller_id = multiplayer.get_remote_sender_id()

	if players[peer_id].get("has_spawned") == true:
		GlobalLogger.log("[%s] Did not spawn peer '%s', already exists!" % [caller_id, peer_id], Enum.LogLevel.WARNING)
		return

	GlobalLogger.log("[%s] Spawning peer '%s'" % [caller_id, peer_id])

	if module_active == false:
		GlobalLogger.log("[%s] Could not spawn peer '%s', module inactive." % [caller_id, peer_id])
		return

	var _player_scene: PackedScene = load("res://scenes/players/player.tscn")
	var _new_player: Node3D = _player_scene.instantiate()
	_new_player.name = str(peer_id)
	_new_player.position = Vector3(0, 0, 0)
	_new_player.set_multiplayer_authority(int(peer_id))
	get_node("../root").add_child(_new_player)
	var player_node = get_node("../root").get_node(str(peer_id))
	GlobalLogger.log("[%s] Spawned peer '%s'." % [caller_id, peer_id])
	players[peer_id].set("node", player_node)
	players[peer_id].set("has_spawned", true)
	return


func kill_player() -> void:
	GlobalLogger.log("'%s' is not implemented." % get_stack()[0]["function"], Enum.LogLevel.WARNING)
	return
