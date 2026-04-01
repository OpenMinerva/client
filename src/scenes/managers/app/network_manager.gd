# --- License
# File: /client/src/scenes/managers/app/network_manager.gd
# Project: OpenMinerva
# Created Date: 05 February 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License

extends Node

var n_c = preload("res://scripts/network/network_compression.gd").new()
var rsa = preload("res://scripts/crypto/rsa.gd").new()
var url_regex = RegEx.create_from_string("^(https?)://([^/:]+)(?::(\\d+))?(.*)$")

# TODO: Bandwidth toggles
@onready var scene_manager = get_tree().current_scene.get_node("SceneManager")
@onready var rpc_lib = get_tree().current_scene.get_node("RpcManager")

var active_session = ""

# This file contains all of the session management and client communication.
# Anything that goes through the network should first route through here at some point.
enum server_privacy {PRIVATE, INVITE, FRIENDS, PUBLIC}

var status = {
	"hosting": false,
	"client": false
}

var config = {
	"port": 20205,
	"max_clients": 4,
	"privacy": 0,

	"networking": {
		"use_steam": false,
		"use_lan": false
	}
}

var info = {
	"level": "res://scenes/levels/home.tscn",
	"level_node_name": "",
	"clients": []
}

func start_server(port: int = config.port, max_clients: int = config.max_clients, ignore_port: bool = false) -> void:
	# TODO: In ignore_port = true, keep trying to make a server until it succeeds. 
	if status.hosting:
		# This ideally should not trigger
		GlobalLogger.logs("Can not start server: Server is already running.", 2)
		status.hosting = false
		status.client = false
		return

	var new_peer = ENetMultiplayerPeer.new()
	# FIXME: Error handling is required here
	info.clients.append({"username": "Me!", "multiplayer_id": 1})
	var err = new_peer.create_server(port, max_clients)
	# FIXME: This client append is happening too early, this is a debug position

	if err == 20:
		# Port is in use
		GlobalLogger.logs("Failed to start server: Is the port in use?", 1)
		# FIXME: HACK: Just try again with the default port + 1.
		err = new_peer.create_server(port + 1, max_clients)
		status.hosting = false
		status.client = false

	if err != OK:
		GlobalLogger.logs("Failed to start server. Error: '%s'" % err, 1)
		status.hosting = false
		status.client = false
		return


	multiplayer.multiplayer_peer = new_peer
	GlobalLogger.logs("Successfully started server.", 1)

	while status.hosting == false:
		await get_tree().process_frame
		status.hosting = true
		status.client = false

	# TODO: Hardcoded spawn host value, is there a better way?
	rpc_lib.com.on_spawn_player(1)

func close_server():
	# Disconnect all players.
	# Remove listings from all used networking.
	# Update server config.
	# TODO: OfflineMultiplayerPeer is a test. Check to see if this actually works.
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	status.hosting = false
	status.client = false

	return

func update_server():
	# Update our config.
	# Submit a update to any active networking service.
	GlobalLogger.logs("Not implemented.", 3)
	return

func join_server(ip: String = "", port: int = config.port) -> void:
	# Client connects to a server.
	if ip.is_empty():
		GlobalLogger.logs("No IP to connect to.", 2)
		return
	
	if status.hosting:
		# This ideally should not trigger
		GlobalLogger.logs("Can not join server: We are currently hosting a server.", 2)
		close_server()
		# return
	
	var new_peer = ENetMultiplayerPeer.new()
	new_peer.create_client(ip, port)
	multiplayer.multiplayer_peer = new_peer

	status.hosting = false
	status.client = true
	GlobalLogger.logs("Connected to the server.", 1)
	return

func kick_player(player_id: int, reason: String = "No reason specified"):
	# Server kicks a player from the session.
	GlobalLogger.logs("Not implemented.", 3)
	return

func ban_player():
	# Server permanatly bans a user.
	GlobalLogger.logs("Not implemented.", 3)
	return

func set_networking_config(options: Dictionary) -> void:
	if !options:
		GlobalLogger.logs("Tried to set networking config without options", 2)
		return
	
	# LAN connections
	if options.lan == true:
		config.use_lan = true
	else:
		config.use_lan = false

	# Steam connections
	if options.steam == true:
		config.use_steam = true
	else:
		config.use_steam = false

func parse_url(url: String) -> Dictionary:
	var result = {
		"scheme": "",
		"host": "",
		"port": 0,
		"path": ""
	}

	var matches = url_regex.search(url)
	if matches:
		result["scheme"] = matches.get_string(1).to_lower()
		result["host"] = matches.get_string(2)
		result["port"] = int(matches.get_string(3)) if matches.get_string(3) != "" else (443 if result["scheme"] == "https" else 80)
		result["path"] = matches.get_string(4) if matches.get_string(4) != "" else "/"

	return result

func spawn_player(player):
	# FIXME: Placeholder for refactor
	while scene_manager.get_current_session_node() == null:
		await get_tree().process_frame
	
	scene_manager.get_current_session_node().call_deferred("add_child", player)

func player_exists(name: String) -> Node3D:
	# FIXME: Placeholder for refactor
	var target_node = scene_manager.get_current_session_node().get_node_or_null(name)
	
	return target_node
