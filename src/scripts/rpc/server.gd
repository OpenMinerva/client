# --- License
# File: /client/src/scripts/rpc/server.gd
# Project: OpenMinerva
# Created Date: 05 February 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License

extends Node

var n_c = preload("res://scripts/network/network_compression.gd").new()
var jwt = preload("res://scripts/libs/jwt.gd").new()
var rsa = preload("res://scripts/crypto/rsa.gd").new()
var url_regex = RegEx.create_from_string("^(https?)://([^/:]+)(?::(\\d+))?(.*)$")

@onready var network_manager = get_tree().current_scene.get_node("NetworkManager")

# Create server
# Update server
# Close server

# On player connecting
# On player connected
# On player leaving
# On player kicked
# On player banned

func on_peer_connected(peer_id):
	if multiplayer.is_server() == false:
		return

	GlobalLogger.logs("[%s] Peer connected: '%s'. Sending server info." % [multiplayer.get_unique_id(), peer_id])
	get_parent().c.rpc_id(peer_id, "on_receive_server_info", network_manager.info)
	
func on_peer_disconnected():
	return

# @rpc("any_peer", "reliable")
# func on_receive_player_info(info) -> void:
# 	if multiplayer.is_server() == false:
# 		return
# 	var sender_id = multiplayer.get_remote_sender_id()
# 	GlobalLogger.logs("Got client info!")
# 	var player_info = jwt.decode(info)

# 	if player_info.ok != true:
# 		GlobalLogger.logs("Unknown error decoding player JWT.", 3)

# 	player_info = player_info.data
# 	var url_parts = _parse_url(player_info.payload.issuer)
# 	var host_pub_key = await AccountServers._request_server_pem(url_parts.host, url_parts.port)

# 	if host_pub_key.ok != true:
# 		GlobalLogger.logs("Unknown error retrieving account server Public PEM.", 3)

# 	host_pub_key = host_pub_key.data
# 	var jwt_is_valid = rsa.verify_jwt_signature(info, host_pub_key)

# 	if jwt_is_valid == false:
# 		GlobalLogger.logs("JWT signature did not match.", 1)
# 		multiplayer.multiplayer_peer.disconnect_peer(sender_id)
# 		# TODO: Send a message before kicking the user.
# 		return

# 	player_info.payload["multiplayer_id"] = sender_id

# 	network_manager.info.clients.append(player_info.payload)

# 	get_parent().com.on_spawn_player(sender_id)
# 	get_parent().com.rpc("on_spawn_player", sender_id)

# 	for client in network_manager.info.clients:
# 		if client.multiplayer_id == sender_id:
# 			continue
# 		get_parent().com.rpc_id(sender_id, "on_spawn_player", client.multiplayer_id)

# 	send_server_info()

func send_server_info():
	get_parent().c.rpc("received_server_session_info", network_manager.info)
	return

func _parse_url(url: String) -> Dictionary:
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
