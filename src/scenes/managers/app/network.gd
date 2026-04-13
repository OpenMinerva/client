# --- License
# File: /client/src/scenes/managers/app/network.gd
# Project: OpenMinerva
# Created Date: 13 April 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License

extends Node

var n_c = preload("res://scripts/network/network_compression.gd").new()
var url_regex = RegEx.create_from_string("^(https?)://([^/:]+)(?::(\\d+))?(.*)$")

@onready var scene_manager = get_tree().current_scene.get_node("SceneManager")
@onready var rpc_lib = get_tree().current_scene.get_node("RpcManager")

var _database = {
	"sessions": {},
	"sessions_api": {}
}

const _instance_database_template = {
	"instance_name": "",
	"instance_description": "",
	"port": 0,
	"max_connected_users": 1,
	"instance_privacy": null,

	"connected_players": [],
	"start_time": 0,

	"networking": {
		"use_steam": false,
		"use_lan": false
	}
}

func start_server(root_scene: Enum.BaseLevel, port: int):
	# Get an available port. If port was defined, force that port or fail.
	# Create a new peer.
	# Create server master scene.
	# Create server root scene.
	# Start session managers. (Handles players, spawning, permissions (as host))
	return

func stop_server(id: String):
	# Kick all players (Server closing). 
	# Turn off all join requests.
	# Destroy multiplayer api.
	# Stop all managers.
	# Destroy server master scene.
	return

func update_server(id: String, update_dict: Dictionary):
	# Get server from database.
	# Validate server updated data.
	# Update the database entry.
	# Emit server updated event to the server.
	return

func join_server(ip: String, port: int):
	# Create multiplayer peer.
	# Establish connection.
	# Host handles everything after this with the managers?
	return

func leave_server():
	# Get server from database.
	# Send leave packet.
	# Destroy multiplayer API.
	# Destroy server master scene.
	return

func kick_player():
	GlobalLogger.logs("'%s' is not implemented." % get_stack()[0]["name"])
	return

func ban_player():
	GlobalLogger.logs("'%s' is not implemented." % get_stack()[0]["name"])
	return

func on_kicked():
	GlobalLogger.logs("'%s' is not implemented." % get_stack()[0]["name"])
	return

func on_banned():
	GlobalLogger.logs("'%s' is not implemented." % get_stack()[0]["name"])
	return

func _find_available_port(target_port: int = 20205):
	GlobalLogger.logs("Trying to find an available port starting at '%s'." % target_port)
	var found_port = 0

	while found_port == 0:
		var port_available = !_is_port_in_use(target_port)
		if port_available:
			found_port = port_available

		target_port = target_port + 1

	GlobalLogger.logs("Port found: '%s'" % target_port)

	return found_port

func _is_port_in_use(port: int) -> bool:
	var tcp_server = TCPServer.new()
	var err = tcp_server.listen(port, "*")

	if err == OK:
		tcp_server.stop()
		return true

	return false