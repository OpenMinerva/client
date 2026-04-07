# --- License
# File: /client/src/scenes/managers/app/network_manaager.gd
# Project: OpenMinerva
# Created Date: 06 April 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License

extends Node

@onready var scene_manager = get_tree().current_scene.get_node("SceneManager")
@onready var rpc_lib = get_tree().current_scene.get_node("RpcManager")

enum PrivacyLevel {
	INVITE = 0,
	PUBLIC = 1,
	CONTACTS_PLUS = 2,
	CONTACTS = 3,
	FRIENDS_PLUS = 4,
	FRIENDS = 5
}

enum BaseLevel {
	DEBUG = 0,
	EMPTY = 1,
	GRID = 2,
}

var _status = {
	"focused_world": "",
	# Keeps a running list of all sessions we are connected to.
	"sessions": {

	}
}
# TODO: Get account username

func start_server(port: int, base_level: BaseLevel) -> void:
	# ! In Godot 4, you can not adjust the maximum connected clients without restarting the server. We will just reject join requests if they would go over the limit. 
	const MAX_CLIENTS = 1000

	GlobalLogger.logs("Trying to start a new server. Port: '%s', Level: '%s'" % [port, base_level])
	var new_peer = ENetMultiplayerPeer.new()

	var err = new_peer.create_server(port, MAX_CLIENTS)
	if err == 20:
		# TODO: Handle port conflicts, try a different port?
		GlobalLogger.logs("Failed to start server: Is the port in use?", 1)
		return

	if err != OK:
		GlobalLogger.logs("Failed to start server. Error: '%s'" % err, 1)
		return

	var _entry = _get_session_entry()
	var _entry_id = _entry.keys()[0]
	_status.sessions[_entry_id] = _entry[_entry_id]
	_status.sessions[_entry_id]["multiplayer_peer"] = new_peer
	_status.sessions[_entry_id]["base_level"] = base_level

	GlobalLogger.logs("Successfully started server.", 1)

	match _status.sessions[_entry_id]["base_level"]:
		BaseLevel.DEBUG:
			GlobalLogger.logs("Loading the debug world template.")
			await scene_manager.load_multiplayer_scene("res://scenes/levels/home.tscn", _entry_id)
		BaseLevel.GRID:
			GlobalLogger.logs("Loading the grid world template.")
			await scene_manager.load_multiplayer_scene("res://scenes/levels/grid.tscn", _entry_id)

	# Force spawn the host.
	rpc_lib.com.on_spawn_player(1)
	return

func _get_session_entry() -> Dictionary:
	var session_id = Random.random_string()

	# TODO: Find first unused port and use that.

	var entry = {
		session_id: {
			"multiplayer_peer": null,
			"instance_name": "",
			"instance_description": "",
			"port": 20205,
			"max_connected_users": 1,
			"instance_privacy": PrivacyLevel.INVITE,

			"user_list": [],
			"base_level": BaseLevel.DEBUG,

			"kick_afk": false,
			"kick_afk_timeout": 300,
			"clean_unused_assets": false,
			"clean_timeout": 300,
			"autosave": false,
			"autosave_timeout": 300,

			"networking": {
				"use_steam": false,
				"use_lan": true
			}
		}
	}
	return entry

func spawn_player(player):
	# FIXME: Placeholder for refactor
	while scene_manager.get_current_session_node() == null:
		await get_tree().process_frame
	
	scene_manager.get_current_session_node().call_deferred("add_child", player)

func get_active_sessions() -> Array:
	var result = []

	for session_id in _status.sessions.keys():
		result.append(_status.sessions[session_id].merged({"id": session_id}))

	return result