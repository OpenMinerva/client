# --- License
# File: /client/src/scrips/libs/server_peer_helper.gd
# Project: OpenMinerva
# Created Date: 26 July 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
class_name ServerPeerHelper

# TODO: Is this safe?
static var tree = Engine.get_main_loop() as SceneTree

static func create_server(port: int, max_clients: int, master_scene_path: String) -> SceneMultiplayer:
	var _session_api = SceneMultiplayer.new()
	var _session_peer = ENetMultiplayerPeer.new()

	var _create_response = _session_peer.create_server(port, max_clients)

	if _create_response != OK:
		GlobalLogger.log("Failed to create a server. Error: '%s'" % _create_response, Enum.LogLevel.INFO)
		return null

	# Set the multiplayer peer for the api to the ENetMultiplayer peer.
	_session_api.multiplayer_peer = _session_peer

	# Set the root path for the multiplayer api
	tree.set_multiplayer(_session_api, master_scene_path)

	return _session_api

static func create_client(ip: String, port: int, master_scene_path: String) -> SceneMultiplayer:
	var _session_api = SceneMultiplayer.new()
	var _session_peer = ENetMultiplayerPeer.new()

	var _create_response = _session_peer.create_client(ip, port)

	if _create_response != OK:
		GlobalLogger.log("Failed to create a client. Error: '%s'" % _create_response, Enum.LogLevel.INFO)
		return null

	# Set the multiplayer peer for the api to the ENetMultiplayer peer.
	_session_api.multiplayer_peer = _session_peer

	# Set the root path for the multiplayer api
	tree.set_multiplayer(_session_api, master_scene_path)

	return _session_api
