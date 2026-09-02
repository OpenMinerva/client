# --- License
# File: /client/src/scenes/managers/app/network.gd
# Project: OpenMinerva
# Created Date: 13 April 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Node

const MAX_CLIENTS = 1000

@onready var registry: Node = get_node("Registry")
@onready var port_scanner: Node = get_node("PortScanner")
@onready var advertiser: Node = get_node("Advertiser")
@onready var scene_m = get_node("../SceneManager")


func start_server(port: int = 0, root_scene: Enum.BaseLevel = Enum.BaseLevel.GRID, scene_dir: String = "") -> bool:
	GlobalLogger.log("Starting a new server.")

	# Get an available port. If port was defined, force that port or fail.
	if port != 0:
		GlobalLogger.log("Forcing port '%s'" % port)
		var port_available = !port_scanner.is_port_in_use(port)
		if !port_available:
			GlobalLogger.log("Could not open server on port '%s', unavailable." % port)
			return false
	else:
		port = port_scanner.find_available_port()

	# Create server master scene.
	var _scene: String = scene_m.create_master_scene()

	# Get a reference to the master scene from our scene ID.
	var master_scene: Node3D = scene_m.get_master_scene(_scene)

	# Create a new server and peer.
	var _mp_api = ServerPeerHelper.create_server(port, MAX_CLIENTS, master_scene.get_path())

	# Check if _mp_api was successfull.
	if _mp_api == null:
		GlobalLogger.log("Failed to start server.", Enum.LogLevel.INFO)
		scene_m.destroy_master_scene(_scene)
		return false

	var net_manager = master_scene.get_node("NetworkManager")
	net_manager.setup_connection(_mp_api, _scene)

	registry.add_session(_scene, "", registry.SessionConnectionType.HOST, port, 1, Enum.PrivacyLevel.INVITE, _mp_api)

	# Create server root scene.
	scene_m.set_master_root_from_program(_scene, root_scene, scene_dir)

	scene_m.start_master_scene(_scene)
	scene_m.set_active_session(_scene)

	var _session_ready: bool = false
	while _session_ready == false:
		# TODO: Safety and breakout.
		_session_ready = scene_m.is_scene_ready(_scene)
		await get_tree().process_frame

	# FIXME: Force spawn the host. This is probably bad design.
	scene_m.get_master_scene(_scene).get_node("NetworkManager")._on_peer_connected(1)

	Events.dash_session_changed.emit(_scene)
	Events.session_joined.emit()

	return true


func stop_server(session_id: String):
	var _is_valid: bool = registry.has_session(session_id)
	GlobalLogger.log("Stopping server '%s'." % session_id)

	# TODO: Disable join requests to server.

	if _is_valid == false:
		GlobalLogger.log("Session '%s' does not exist, cannot stop the server." % session_id, Enum.LogLevel.WARNING)
		return

	var session: Dictionary = registry.get_session(session_id)

	var mp_api: SceneMultiplayer = session.api
	var all_peers = mp_api.get_peers()

	# Kick all players
	for _peer in all_peers:
		kick_player(session_id, _peer, "Server Closing")

	# Close the server
	mp_api.multiplayer_peer.close()
	mp_api.multiplayer_peer = null

	# If we are in this session, go to the previous one.
	if scene_m.active_session == session_id:
		var _next_session: String = registry.get_previous()
		if _next_session.is_empty() == true:
			if StateManager.app_closing == false:
				GlobalLogger.log("There is no session to move to. You are now probably in the void!", Enum.LogLevel.ERROR)
			return
		scene_m.set_active_session(_next_session)

	# Application cleanup
	scene_m.stop_master_scene(session_id)
	scene_m.destroy_master_scene(session_id)

	for _listing in session.session_server_keys:
		advertiser.destroy_session(session.id, _listing.key, _listing.url)

	# Database cleanup
	registry.remove_session(session_id)

	Events.emit_signal("session_left")
	return


func update_server(session_id: String, server_info: Dictionary):
	GlobalLogger.log("Updating server '%s'." % session_id)

	var _saved_session_servers = SettingsManager.get_session_servers()
	var _server: Dictionary = registry.get_session(session_id)
	var _current_listings: Array[String] = []

	# Update our current listings.
	for _listing in _server.session_server_keys:
		GlobalLogger.log("Updating session '%s'" % _server.id)
		_current_listings.append(_listing.url)

		# Invite only sessions are completely delisted
		if server_info.privacy == Enum.PrivacyLevel.INVITE:
			advertiser.destroy_session(session_id, _listing.key, _listing.url)
			continue

		# Otherwise send an update request to the server
		await advertiser.update_session(server_info, _listing.key, _listing.url)
		continue

	if server_info.privacy > Enum.PrivacyLevel.INVITE:
		# List on session servers we were not on before.
		for _session_server in _saved_session_servers:
			if _current_listings.has(_session_server.url) == true:
				continue

			var _server_key = await advertiser.create_session(server_info, _session_server.url)
			if _server_key != "":
				registry.add_session_server_key(session_id, _session_server.url, _server_key)

	Events.emit_signal("instance_updated")
	return


func join_server(ip: String = "", port: int = 0) -> bool:
	GlobalLogger.log("Joining server at '%s:%s'" % [ip, port], Enum.LogLevel.INFO)
	var _port_is_valid = port > 0 && port < 65535

	if ip.is_empty() || !_port_is_valid:
		GlobalLogger.log("Server information is invalid '%s:%s'." % [ip, port], Enum.LogLevel.INFO)
		return false

	# Create server master scene.
	var _scene: String = scene_m.create_master_scene()

	var _session_ready: bool = false
	while _session_ready == false:
		# TODO: Safety and breakout.
		_session_ready = scene_m.is_scene_ready(_scene)
		await get_tree().process_frame

	# Get a reference to the master scene from our scene ID.
	var master_scene: Node3D = scene_m.get_master_scene(_scene)

	# Create a new client peer.
	var _mp_api = ServerPeerHelper.create_client(ip, port, master_scene.get_path())

	# Check if _mp_api was successfull.
	if _mp_api == null:
		GlobalLogger.log("Failed to join server.", Enum.LogLevel.INFO)
		scene_m.destroy_master_scene(_scene)
		return false

	var net_manager = master_scene.get_node("NetworkManager")
	net_manager.setup_connection(_mp_api, _scene)

	registry.add_session(_scene, "", registry.SessionConnectionType.CLIENT, port, 1, Enum.PrivacyLevel.INVITE, _mp_api)

	scene_m.set_active_session(_scene)

	Events.emit_signal("session_joined")
	return true


func leave_server(session_id: String):
	GlobalLogger.log("Trying to leave server '%s'." % session_id)

	var _is_valid: bool = registry.has_session(session_id)

	if _is_valid == false:
		GlobalLogger.log("Session '%s' does not exist, cannot disconnect." % session_id, Enum.LogLevel.WARNING)
		return

	var session: Dictionary = registry.get_session(session_id)
	var mp_api: SceneMultiplayer = session.api

	if mp_api.is_server():
		GlobalLogger.log("Tried to leave a server we are the host of, stopping the server.")
		stop_server(session_id)
		return

	if mp_api.multiplayer_peer:
		mp_api.multiplayer_peer.close()
		GlobalLogger.log("Disconnected from session '%s'." % session_id, Enum.LogLevel.DEBUG)

	if scene_m.active_session == session_id:
		var _previous_session: String = registry.get_previous()
		if _previous_session.is_empty() == true:
			if StateManager.app_closing == false:
				GlobalLogger.log("There is no session to move to. You are now probably in the void!", Enum.LogLevel.ERROR)
			return
		scene_m.set_active_session(_previous_session)

	scene_m.stop_master_scene(session_id)
	scene_m.destroy_master_scene(session_id)

	registry.remove_session(session_id)

	GlobalLogger.log("Successfully disconnected from session '%s' and cleaned up." % session_id, Enum.LogLevel.DEBUG)
	Events.emit_signal("session_left")
	return


func kick_player(server_id: String, peer_id: int, reason: String):
	GlobalLogger.log("Kicking peer '%s' from '%s' for reason '%s'" % [peer_id, server_id, reason], Enum.LogLevel.DEBUG)
	var _is_valid: bool = registry.has_session(server_id)

	# TODO: Check if peer exists
	if _is_valid == true:
		var session: Dictionary = registry.get_session(server_id)
		var mp_api: SceneMultiplayer = session.api
		# TODO: Notify user of kick
		mp_api.disconnect_peer(peer_id)
	return


## @deprecated: Use registry.get_all()
func get_connected_sessions():
	GlobalLogger.log("Deprecated call '%s'" % get_stack()[0]["function"], Enum.LogLevel.WARNING)
	return registry.get_all()


func set_active_session(session_id: String):
	var _is_valid: bool = registry.has_session(session_id)

	if _is_valid:
		GlobalLogger.log("Tried to mark an invalid session as active: '%s'" % session_id, Enum.LogLevel.WARNING)
		return

	for _connected_session_id in registry.get_all_ids():
		var _session: Dictionary = registry.get_session(_connected_session_id)
		var _my_session_id = _session.api.multiplayer.get_unique_id()
		scene_m.get_master_root(_connected_session_id).get_node("PlayerManager").players.get(_my_session_id).get("node").camera.current = false

	var _target_session: Dictionary = registry.get_session(session_id)

	var my_id = _target_session.api.multiplayer.get_unique_id()
	scene_m.get_master_root(session_id).get_node("PlayerManager").players.get(my_id).get("node").camera.current = true
	scene_m.set_active_session(session_id)
	Events.dash_session_changed.emit(session_id)
	return
