# --- License
# File: /client/src/scenes/managers/app/network.gd
# Project: OpenMinerva
# Created Date: 13 April 2026
# Copyright (c) 2026 OpenMinerva Contributors
# License: MIT License
# --- License
extends Node

const MAX_CLIENTS = 1000

@onready var registry: Node = get_node("Registry")
@onready var port_scanner: Node = get_node("PortScanner")
@onready var advertiser: Node = get_node("Advertiser")
@onready var app_scene_m: Node = get_tree().root.find_child("AppSceneManager", true, false)


func _ready():
	Events.action_start_session.connect(start_session)
	return


func start_session(port: int = 0, root_scene: Enum.BaseLevel = Enum.BaseLevel.GRID, scene_dir: String = "") -> bool:
	GlobalLogger.log("Starting a new session.")
	var _session_ready: bool = false

	# Get an available port. If port was defined, force that port or fail.
	if port != 0:
		GlobalLogger.log("Forcing port '%s'" % port)
		var port_available = !port_scanner.is_port_in_use(port)
		if !port_available:
			GlobalLogger.log("Could not open session on port '%s', unavailable." % port)
			return false
	else:
		port = port_scanner.find_available_port()

	# Create session master scene.
	var _session_id: String = app_scene_m.create_session_master()
	var _session_master_node: Node3D = app_scene_m.get_session_master(_session_id)
	var _sess_network_m: Node = _session_master_node.get_manager(_session_master_node.MANAGER_TYPE.NETWORK)

	# Create a new session and peer.
	var _mp_api = SessionPeerHelper.create_session(port, MAX_CLIENTS, _session_master_node.get_path())

	# Check if _mp_api was successful.
	if _mp_api == null:
		GlobalLogger.log("Failed to start session.", Enum.LogLevel.INFO)
		app_scene_m.destroy_master_scene(_session_id)
		return false

	_sess_network_m.setup_connection(_mp_api, _session_id)

	registry.add_session(_session_id, "", registry.SessionConnectionType.HOST, port, 1, Enum.PrivacyLevel.INVITE, _mp_api)

	# Create session root scene.
	app_scene_m.set_session_master_root_from_program(_session_id, root_scene, scene_dir)

	app_scene_m.set_active_session(_session_id)

	while _session_ready == false:
		# TODO: Safety and breakout.
		_session_ready = app_scene_m.is_scene_ready(_session_id)
		await get_tree().process_frame

	# FIXME: Force spawn the host. This is probably bad design.
	_sess_network_m._on_peer_connected(1)

	Events.dash_session_changed.emit(_session_id)
	Events.session_joined.emit()

	return true


func stop_session(session_id: String):
	GlobalLogger.log("Stopping session '%s'." % session_id)

	var _is_valid: bool = registry.has_session(session_id)

	if _is_valid == false:
		GlobalLogger.log("Session '%s' does not exist in the registry, cannot stop the session." % session_id, Enum.LogLevel.WARNING)
		return

	var session: Dictionary = registry.get_session(session_id)

	var mp_api: SceneMultiplayer = session.api
	var all_peers = mp_api.get_peers()

	# Kick all players
	for _peer in all_peers:
		kick_player(session_id, _peer, "Session Closing")

	# Close the session
	mp_api.multiplayer_peer.close()
	mp_api.multiplayer_peer = null

	# If we are in this session, go to the previous one.
	if app_scene_m.active_session == session_id:
		var _next_session: String = registry.get_previous()
		if _next_session.is_empty() == true:
			if StateManager.app_closing == false:
				GlobalLogger.log("There is no session to move to. You are now probably in the void!", Enum.LogLevel.ERROR)
		else:
			app_scene_m.set_active_session(_next_session)

	# Application cleanup
	app_scene_m.destroy_session_master(session_id)

	for _listing in session.session_server_keys:
		advertiser.destroy_session(session.id, _listing.key, _listing.url)

	# Registry cleanup
	registry.remove_session(session_id)

	Events.emit_signal("session_left")
	return


func update_session(session_id: String, session_info: Dictionary):
	GlobalLogger.log("Updating session '%s'." % session_id)

	var _saved_session_servers = SettingsManager.get_session_servers()
	var _session: Dictionary = registry.get_session(session_id)
	var _current_listings: Array[String] = []

	# Update our current listings.
	for _listing in _session.session_server_keys:
		GlobalLogger.log("Updating session '%s'" % _session.id)
		_current_listings.append(_listing.url)

		# Invite only sessions are completely delisted
		if session_info.privacy == Enum.PrivacyLevel.INVITE:
			advertiser.destroy_session(session_id, _listing.key, _listing.url)
			continue

		# Otherwise send an update request to the server
		await advertiser.update_session(session_info, _listing.key, _listing.url)
		continue

	if session_info.privacy > Enum.PrivacyLevel.INVITE:
		# List on session servers we were not on before.
		for _session_server in _saved_session_servers:
			if _current_listings.has(_session_server.url) == true:
				continue

			var _session_key = await advertiser.create_session(session_info, _session_server.url)
			if _session_key != "":
				registry.add_session_server_key(session_id, _session_server.url, _session_key)

	Events.emit_signal("instance_updated")
	return


func join_session(ip: String = "", port: int = 0) -> bool:
	GlobalLogger.log("Joining session at '%s:%s'" % [ip, port], Enum.LogLevel.INFO)
	var _port_is_valid = port > 0 && port < 65535

	if ip.is_empty() || !_port_is_valid:
		GlobalLogger.log("Session information is invalid '%s:%s'." % [ip, port], Enum.LogLevel.INFO)
		return false

	# Create session master scene.
	var _session_id: String = app_scene_m.create_session_master()

	await app_scene_m.await_session_ready(_session_id)

	# Get a reference to the master scene from our scene ID.
	var _session_master_node: Node3D = app_scene_m.get_session_master(_session_id)
	var _sess_network_m: Node = _session_master_node.get_manager(_session_master_node.MANAGER_TYPE.NETWORK)
	var _mp_api = SessionPeerHelper.create_client(ip, port, _session_master_node.get_path())

	# Check if _mp_api was successful.
	if _mp_api == null:
		GlobalLogger.log("Failed to join session.", Enum.LogLevel.INFO)
		app_scene_m.destroy_master_scene(_session_id)
		return false

	_sess_network_m.setup_connection(_mp_api, _session_id)

	registry.add_session(_session_id, "", registry.SessionConnectionType.CLIENT, port, 1, Enum.PrivacyLevel.INVITE, _mp_api)

	app_scene_m.set_active_session(_session_id)

	Events.emit_signal("session_joined")
	return true


func leave_session(session_id: String):
	GlobalLogger.log("Trying to leave session '%s'." % session_id)

	if registry.has_session(session_id) == false:
		GlobalLogger.log("Session '%s' does not exist, cannot disconnect." % session_id, Enum.LogLevel.WARNING)
		return

	var _session: Dictionary = registry.get_session(session_id)
	var _mp_api: SceneMultiplayer = _session.api

	if _mp_api.is_server():
		GlobalLogger.log("Tried to leave a session we are the host of, stopping the session.")
		stop_session(session_id)
		return

	if _mp_api.multiplayer_peer:
		_mp_api.multiplayer_peer.close()
		GlobalLogger.log("Disconnected from session '%s'." % session_id, Enum.LogLevel.DEBUG)

	if app_scene_m.active_session == session_id:
		var _previous_session: String = registry.get_previous()
		if _previous_session.is_empty() == true:
			if StateManager.app_closing == false:
				GlobalLogger.log("There is no session to move to. You are now probably in the void!", Enum.LogLevel.ERROR)
			return
		app_scene_m.set_active_session(_previous_session)

	app_scene_m.destroy_session_master(session_id)

	registry.remove_session(session_id)

	GlobalLogger.log("Successfully disconnected from session '%s' and cleaned up." % session_id, Enum.LogLevel.DEBUG)
	Events.emit_signal("session_left")
	return


func kick_player(session_id: String, peer_id: int, reason: String):
	GlobalLogger.log("Kicking peer '%s' from '%s' for reason '%s'" % [peer_id, session_id, reason], Enum.LogLevel.DEBUG)
	var _is_valid: bool = registry.has_session(session_id)

	# TODO: Check if peer exists
	if _is_valid == true:
		var session: Dictionary = registry.get_session(session_id)
		var mp_api: SceneMultiplayer = session.api
		# TODO: Notify user of kick
		mp_api.disconnect_peer(peer_id)
	return


## @deprecated: Use registry.get_all()
func get_connected_sessions():
	GlobalLogger.log("Deprecated call '%s'" % get_stack()[0]["function"], Enum.LogLevel.WARNING)
	return registry.get_all()
