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
const MINIMUM_INCREMENTAL_PORT = 20205
# TODO: This interal DB template assumes only a single session server is being advertised to.
const _instance_database_template = {
	"public_id": "",
	"name": "",
	"description": "",
	"port": 0,
	"max_connected_users": 1,
	"privacy": null,
	"active": false,
	"connected_players": [],
	"start_time": 0,
	"networking": {
		"use_steam": false,
		"use_lan": false,
	},
}

var url_regex: RegEx = RegEx.create_from_string("^(https?)://([^/:]+)(?::(\\d+))?(.*)$")
var _session_db = { }
var _heartbeats = { }

@onready var scene_m = get_node("../SceneManager")


func start_server(port: int = 0, root_scene: Enum.BaseLevel = Enum.BaseLevel.GRID, scene_dir: String = "") -> bool:
	GlobalLogger.log("Starting a new server.")

	# Get an available port. If port was defined, force that port or fail.
	if port != 0:
		GlobalLogger.log("Forcing port '%s'" % port)
		var port_available = !_is_port_in_use(port)
		if !port_available:
			GlobalLogger.log("Could not open server on port '%s', unavailable." % port)
			return false
	else:
		port = _find_available_port()

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

	_session_db.set(_scene, _create_instance_db_entry(_mp_api, _scene, Enum.PrivacyLevel.INVITE, port, "host"))

	# Create server root scene.
	scene_m.set_master_root_from_program(_scene, root_scene, scene_dir)

	scene_m.start_master_scene(_scene)
	scene_m.set_active_session(_scene)

	# FIXME: Force spawn the host. This is probably bad design.
	scene_m.get_master_scene(_scene).get_node("NetworkManager")._on_peer_connected(1)

	Events.dash_session_changed.emit(_scene)
	Events.session_joined.emit()

	return true


func stop_server(id: String):
	var _is_valid: bool = _session_db.has(id)
	GlobalLogger.log("Stopping server '%s'." % id)

	# TODO: Disable join requests to server

	if _is_valid == false:
		GlobalLogger.log("Session '%s' does not exist, cannot stop the server." % id, Enum.LogLevel.WARNING)
		return

	var mp_api: SceneMultiplayer = _session_db.get(id).api
	var all_peers = mp_api.get_peers()

	# Kick all players
	for _peer in all_peers:
		kick_player(id, _peer, "Server Closing")

	# Close the server
	mp_api.multiplayer_peer.close()
	mp_api.multiplayer_peer = null

	# Application cleanup
	scene_m.stop_master_scene(id)
	scene_m.destroy_master_scene(id)

	# Database cleanup
	_session_db.erase(id)
	return


func update_server(id: String, server_info: Dictionary):
	GlobalLogger.log("Updating server '%s'." % id)

	var _saved_session_servers = SettingsManager.get_session_servers()

	if server_info.privacy > Enum.PrivacyLevel.INVITE:
		for _server in _saved_session_servers:
			if _heartbeats.has(id):
				GlobalLogger.log("Session '%s' is already advertised. Updating instead." % id)
				await _update_session_server_listing(server_info, _server.url)
			else:
				GlobalLogger.log("Advertising Session '%s'." % id)
				var advertise_response = await _advertise_session(server_info, _server.url)

				if advertise_response.ok == true:
					_session_db[id].public_id = advertise_response.data.id
					_create_heartbeat_timer(server_info.id, _server.url)

	if server_info.privacy == Enum.PrivacyLevel.INVITE:
		if _heartbeats.has(id):
			GlobalLogger.log("Destroying session heartbeat for '%s'" % id)
			_heartbeats.erase(id)

		for _server in _saved_session_servers:
			_remove_session_from_server(id, _server.url)

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

	# TODO: Do we need such a heavy Database entry? Isn't it only used once?
	_session_db.set(_scene, _create_instance_db_entry(_mp_api, _scene, Enum.PrivacyLevel.INVITE, port, "client"))

	scene_m.set_active_session(_scene)

	Events.emit_signal("session_joined")
	return true


func leave_server(id: String):
	GlobalLogger.log("Trying to leave server '%s'." % id)
	var _is_valid: bool = _session_db.has(id)

	if _is_valid == false:
		GlobalLogger.log("Session '%s' does not exist, cannot disconnect." % id, Enum.LogLevel.WARNING)
		return

	var mp_api: SceneMultiplayer = _session_db[id].api

	if mp_api.multiplayer_peer:
		mp_api.multiplayer_peer.close()
		GlobalLogger.log("Disconnected from session '%s'." % id, Enum.LogLevel.DEBUG)

	scene_m.set_active_session(get_connected_sessions()[0].id)

	scene_m.stop_master_scene(id)
	scene_m.destroy_master_scene(id)

	_session_db.erase(id)

	GlobalLogger.log("Successfully disconnected from session '%s' and cleaned up." % id, Enum.LogLevel.DEBUG)
	Events.emit_signal("session_left")
	return


func kick_player(server_id: String, peer_id: int, reason: String):
	GlobalLogger.log("Kicking peer '%s' from '%s' for reason '%s'" % [peer_id, server_id, reason], Enum.LogLevel.DEBUG)
	var _is_valid: bool = _session_db.has(server_id)

	# TODO: Check if peer exists
	if _is_valid == true:
		var mp_api: SceneMultiplayer = _session_db[server_id].api
		# TODO: Notify user of kick
		mp_api.disconnect_peer(peer_id)
	return


func get_connected_sessions():
	var result = []
	# TODO: Is JSON required here?
	for session_id in _session_db.keys():
		result.append(_session_db[session_id].merged({ "id": session_id }))

	return result


func set_active_session(id: String):
	var _is_valid: bool = _session_db.has(id)

	if _is_valid:
		GlobalLogger.log("Tried to mark an invalid session as active: '%s'" % id, Enum.LogLevel.WARNING)
		return

	for session_id in _session_db.keys():
		var _my_session_id = _session_db[session_id].api.multiplayer.get_unique_id()
		_session_db[session_id].active = false
		scene_m.get_master_root(session_id).get_node("PlayerManager").players.get(_my_session_id).get("node").camera.current = false

	var my_id = _session_db[id].api.multiplayer.get_unique_id()
	scene_m.get_master_root(id).get_node("PlayerManager").players.get(my_id).get("node").camera.current = true
	_session_db[id].active = true
	scene_m.set_active_session(id)
	Events.dash_session_changed.emit(id)
	return


func _update_session_server_listing(session_info: Dictionary, session_server: String) -> Dictionary:
	var response_dict = { "ok": false, "error": null, "data": null }

	GlobalLogger.log("Updating session '%s' to the server '%s'" % [session_info.id, session_server])
	var url = UrlParser.deconstruct("%s/api/v1/updateSession" % session_server)

	if url.ok != true:
		GlobalLogger.log("Failed to deconstruct the URL '%s'. Error: '%s'" % [session_server, url.error])
		response_dict.error = url.error
		return response_dict

	url = url.data
	var _api_key = Accounts.get_session_server_token(url.host)
	var _body = {
		"id": _session_db[session_info.id].public_id,
		"session_name": session_info.name,
		"session_description": session_info.description,
		"session_privacy": session_info.privacy,
	}

	var _update_response = await HTTP.req(
		HTTPClient.Method.METHOD_POST,
		url.host,
		url.path,
		url.port,
		["Accept: application/json", "Content-Type: application/json", "x-api-key: %s" % _api_key],
		JSON.stringify(_body),
	)

	return response_dict


func _remove_session_from_server(server_id: String, session_server: String) -> Dictionary:
	var response_dict = { "ok": false, "error": null, "data": { } }
	var _full_url = "%s/api/v1/deleteSession" % session_server

	GlobalLogger.log("Removing session '%s' to the server '%s'" % [server_id, session_server])
	var url = UrlParser.deconstruct(_full_url)

	if url.ok != true:
		GlobalLogger.log("Failed to deconstruct the URL '%s'. Error: '%s'" % [_full_url, url.error])
		response_dict.error = url.error
		return response_dict

	url = url.data
	var _api_key = Accounts.get_session_server_token(url.host)
	var _body = {
		"id": _session_db[server_id].public_id,
	}

	var _removal_response = await HTTP.req(
		HTTPClient.Method.METHOD_DELETE,
		url.host,
		url.path,
		url.port,
		["Accept: application/json", "Content-Type: application/json", "x-api-key: %s" % _api_key],
		JSON.stringify(_body),
	)

	if _removal_response.ok:
		response_dict.ok = true
		response_dict.data = JSON.parse_string(_removal_response.body)
		return response_dict

	response_dict.error = _removal_response.error
	return response_dict


func _find_available_port(target_port: int = MINIMUM_INCREMENTAL_PORT) -> int:
	GlobalLogger.log("Trying to find an available port starting at '%s'." % target_port)
	var _found_port = null
	var _is_found = false

	while _is_found == false:
		var port_available = !_is_port_in_use(target_port)
		if port_available:
			_found_port = target_port
			_is_found = true
			break
		target_port = target_port + 1

	GlobalLogger.log("Port found: '%s'" % target_port)

	return _found_port


func _is_port_in_use(port: int) -> bool:
	var udp_server = UDPServer.new()
	var err_udp = udp_server.listen(port, "*")
	var tcp_server = TCPServer.new()
	var err_tcp = tcp_server.listen(port, "*")

	if err_udp == OK && err_tcp == OK:
		udp_server.stop()
		tcp_server.stop()
		return false

	udp_server.stop()
	tcp_server.stop()
	return true


func _create_heartbeat_timer(session_id: String, session_server_url: String):
	GlobalLogger.log("Creating a heartbeat timer for server '%s'" % session_id)
	var timer = get_tree().create_timer(20)

	_heartbeats[session_id] = timer

	timer.timeout.connect(_heartbeat_timer_timeout.bind(session_id, session_server_url))
	return


func _heartbeat_timer_timeout(session_id: String, session_server_url: String):
	GlobalLogger.log("Sending a heartbeat for server '%s'" % session_id)
	if _heartbeats.has(session_id) == false:
		GlobalLogger.log("Server '%s' does not exist anymore, not sending a heartbeat." % session_id)
		return

	_heartbeat_session(session_id, session_server_url)

	_create_heartbeat_timer(session_id, session_server_url)
	return


func _heartbeat_session(session_id: String, session_server_url: String) -> void:
	var _full_url = "%s/api/v1/heartbeatSession" % session_server_url
	var _url = UrlParser.deconstruct(_full_url)

	if _url.ok != true:
		GlobalLogger.log("Failed to deconstruct the URL '%s'. Error: '%s'" % [_full_url, _url.error])
		return

	_url = _url.data
	var _api_key = Accounts.get_session_server_token(_url.host)
	var body = { "session_id": _session_db[session_id].public_id }

	var response = await HTTP.req(
		HTTPClient.Method.METHOD_POST,
		_url.host,
		_url.path,
		_url.port,
		["Accept: application/json", "Content-Type: application/json", "x-api-key: %s" % _api_key],
		JSON.stringify(body),
	)

	if response and response.get("ok"):
		GlobalLogger.log("Heartbeat sent for session '%s'" % session_id)
	return


func _advertise_session(session_info: Dictionary, session_server: String) -> Dictionary:
	var response_dict = { "ok": false, "error": null, "data": null }
	GlobalLogger.log("Advertising session '%s' to the server '%s'" % [session_info.id, session_server])
	var _full_url = "%s/api/v1/postSession" % session_server
	var url = UrlParser.deconstruct(_full_url)

	if url.ok != true:
		GlobalLogger.log("Failed to deconstruct the URL '%s'. Error: '%s'" % [_full_url, url.error])
		response_dict.error = url.error
		return response_dict

	url = url.data

	var _api_key = Accounts.get_session_server_token(url.host)
	if _api_key == "":
		response_dict.error = "Could not get the account server token."
		return response_dict

	var _body = {
		"session_name": session_info.name,
		"session_description": session_info.description,
		"session_privacy": session_info.privacy,
		"session_port": session_info.port,
	}

	var advertise_response = await HTTP.req(
		HTTPClient.Method.METHOD_POST,
		url.host,
		url.path,
		url.port,
		["Accept: application/json", "Content-Type: application/json", "x-api-key: %s" % _api_key],
		JSON.stringify(_body),
	)

	# FIXME: What is this flow? This is bad?
	if advertise_response.ok != true:
		response_dict.error = advertise_response.error
		return response_dict

	advertise_response = JSON.parse_string(advertise_response.body)
	# FIXME: When logging in, immediately trying to host a session results in a fatal error here.
	print(advertise_response)
	if advertise_response.ok == false:
		response_dict.error = advertise_response.error
		return response_dict

	advertise_response = advertise_response.data

	response_dict.ok = true
	response_dict.data = advertise_response
	return response_dict


func _create_instance_db_entry(api: SceneMultiplayer, name: String, privacy: Enum.PrivacyLevel, port: int, type: String = "host") -> Dictionary:
	var _instance = _instance_database_template.duplicate()

	_instance.api = api
	_instance.name = name
	_instance.start_time = int(Time.get_unix_time_from_system())
	_instance.privacy = privacy
	_instance.port = port
	_instance.type = type

	return _instance
