# --- License
# File: /client/src/scenes/managers/scene/player.gd
# Project: OpenMinerva
# Created Date: 13 April 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License

extends Node

var active: bool = false

var players = []

@rpc("authority", "unreliable")
func add_player(peer_id: int) -> void:
	players.append(peer_id)

@rpc("authority", "unreliable")
func spawn_player(peer_id: String) -> void:
	GlobalLogger.logs("Spawning peer '%s'" % peer_id)
	if active == false:
		GlobalLogger.logs("Could not spawn peer '%s', module inactive." % peer_id)
		return
	var _player_scene: PackedScene = load("res://scenes/players/player.tscn")
	var _new_player: Node3D = _player_scene.instantiate()
	_new_player.name = str(peer_id)
	_new_player.position = Vector3(0, 0, 0)
	_new_player.set_multiplayer_authority(int(peer_id))
	get_parent().get_node("root").call_deferred("add_child", _new_player)
	GlobalLogger.logs("Spawned peer '%s'." % peer_id)
	return

func kill_player() -> void:
	GlobalLogger.logs("'%s' is not implemented." % get_stack()[0]["function"], 3)
	return
