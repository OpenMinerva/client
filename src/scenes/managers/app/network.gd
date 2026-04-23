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

var url_regex = RegEx.create_from_string("^(https?)://([^/:]+)(?::(\\d+))?(.*)$")

@onready var http = preload("res://scripts/network/http.gd").new()
@onready var scene_m = get_tree().current_scene.get_node("SceneManager")
@onready var rpc_lib = get_tree().current_scene.get_node("RpcManager")

var _database = {
	"heartbeats": {},
	"sessions_id": {},
	"sessions": {},
	"sessions_api": {}
}

const _instance_database_template = {
	"id": "",
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
		"use_lan": false
	}
}

func start_server(port: int = 0, root_scene: Enum.BaseLevel = Enum.BaseLevel.GRID) -> Dictionary:
	var response_dict = {"ok": false, "error": null, "data": null}

	# Get an available port. If port was defined, force that port or fail.
	if port != 0:
		GlobalLogger.logs("Forcing port '%s'" % port)
		var port_available = !_is_port_in_use(port)
		if !port_available:
			response_dict.error = "Port is not available."
			return response_dict
	else:
		port = _find_available_port()

	# Create server master scene.
	var _scene: String = scene_m.create_master_scene()
	var _instance = _instance_database_template.duplicate()
	_instance.id = _scene
	_instance.name = _scene
	_instance.start_time = int(Time.get_unix_time_from_system())
	_instance.privacy = Enum.PrivacyLevel.INVITE
	_instance.port = port
	_instance.type = "host"

	# Create a new peer.
	var _mp_api = SceneMultiplayer.new()
	var _session_peer = ENetMultiplayerPeer.new()
	var _create_server_response = _session_peer.create_server(port, MAX_CLIENTS)
	_mp_api.multiplayer_peer = _session_peer

	var master_scene = scene_m.get_master_scene(_scene)
	get_tree().set_multiplayer(_mp_api, master_scene.get_path())
	_mp_api.set_root_path(master_scene.get_path())
	var net_manager = master_scene.get_node("NetworkManager")
	net_manager.setup_connection(_mp_api, _scene)

	_database.sessions_api.set(_scene, _mp_api)
	_database.sessions.set(_scene, _instance)

	if _create_server_response != OK:
		GlobalLogger.logs("Failed to start server. Error: '%s'" % _create_server_response, Enum.LogLevel.INFO)
		response_dict.error = str(_create_server_response)

		_database.sessions_api.erase(_scene)
		_database.sessions.erase(_scene)

		scene_m.destroy_master_scene(_scene)
		# HACK: Retry creating a server again.
		if _create_server_response == 20:
			# Port is in use
			return start_server(0, root_scene)

		return response_dict

	# Create server root scene.
	if root_scene:
		scene_m.set_master_root_from_program(_scene, root_scene)
	else:
		scene_m.set_master_root_from_program(_scene, Enum.BaseLevel.GRID)

	scene_m.start_master_scene(_scene)

	# DEV: Force spawn the host.
	scene_m.get_master_scene(_scene).get_node("PlayerManager").add_player(1)
	scene_m.get_master_scene(_scene).get_node("PlayerManager").spawn_player(str(1))
	scene_m.set_active_session(_scene)

	return response_dict

func stop_server(id: String):
	var database_has_sessions: bool = _database.sessions.has(id)
	var database_has_sessions_api: bool = _database.sessions_api.has(id)

	# TODO: Disable join requests to server

	if !database_has_sessions && !database_has_sessions_api:
		GlobalLogger.logs("Session '%s' does not exist, cannot stop the server." % id, Enum.LogLevel.WARNING)
		return

	if database_has_sessions_api:
		var mp_api: SceneMultiplayer = _database.sessions_api.get(id)
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
	_database.sessions_api.erase(id)
	_database.sessions.erase(id)
	return

func update_server(id: String, server_info: Dictionary):
	# Get server from database.
	# Validate server updated data.
	# Update the database entry.
	# Emit server updated event to the server.
	var _saved_session_servers = SettingsManager.get_session_servers()

	if server_info.privacy > Enum.PrivacyLevel.INVITE:
		for _server in _saved_session_servers:
			if _database.heartbeats.has(id):
				GlobalLogger.logs("Session '%s' is already advertised. Updating instead." % id)
				await _update_session_server_listing(server_info, _server.url)
			else:
				var advertise_response = await _advertise_session(server_info, _server.url)

				if advertise_response.ok == true:
					_database.sessions_id.set(server_info.id, advertise_response.data.id)
					_create_heartbeat_timer(server_info.id, _server.url)

	if server_info.privacy == Enum.PrivacyLevel.INVITE:
		if _database.heartbeats.has(id):
			GlobalLogger.logs("Destroying session heartbeat for '%s'" % id)
			_database.heartbeats.erase(id)

		for _server in _saved_session_servers:
			_remove_session_from_server(id, _server.url)
	return

func join_server(ip: String, port: int):
	var response_dict = {"ok": false, "error": null, "data": null}

	GlobalLogger.logs("Joining server at '%s:%s'" % [ip, port], Enum.LogLevel.INFO)
	var _port_is_valid = port > 0 && port < 65535

	if ip.is_empty() || !_port_is_valid:
		GlobalLogger.logs("Server information is invalid '%s:%s'." % [ip, port], Enum.LogLevel.INFO)
		response_dict.error = "Server information is invalid."
		return response_dict

	# Create server master scene.
	var _scene: String = scene_m.create_master_scene()
	var _instance = _instance_database_template.duplicate()
	_instance.id = _scene
	_instance.name = _scene
	_instance.start_time = int(Time.get_unix_time_from_system())
	_instance.privacy = Enum.PrivacyLevel.INVITE
	_instance.port = port
	_instance.type = "client"

	var _mp_api = SceneMultiplayer.new()
	var _session_peer = ENetMultiplayerPeer.new()
	var connect_error = _session_peer.create_client(ip, port)

	if connect_error != OK:
		GlobalLogger.logs("Failed to join server. Error: '%s'" % connect_error, Enum.LogLevel.INFO)
		response_dict.error = "Failed to join server. Error: '%s'" % connect_error
		return response_dict

	_mp_api.multiplayer_peer = _session_peer

	var master_scene = scene_m.get_master_scene(_scene)
	get_tree().set_multiplayer(_mp_api, master_scene.get_path())
	_mp_api.set_root_path(master_scene.get_path())
	var net_manager = master_scene.get_node("NetworkManager")
	net_manager.setup_connection(_mp_api, _scene)

	_database.sessions_api.set(_scene, _mp_api)
	_database.sessions.set(_scene, _instance)

	Events.emit_signal("session_joined")
	return

func leave_server(id: String):
	var database_has_sessions: bool = _database.sessions.has(id)
	var database_has_sessions_api: bool = _database.sessions_api.has(id)

	if !database_has_sessions && !database_has_sessions_api:
		GlobalLogger.logs("Session '%s' does not exist, cannot disconnect." % id, Enum.LogLevel.WARNING)
		return

	if database_has_sessions_api:
		var mp_api: SceneMultiplayer = _database.sessions_api.get(id)
		var my_peer_id = mp_api.multiplayer_peer.get_unique_id()

		if mp_api.multiplayer_peer:
			mp_api.multiplayer_peer.disconnect_peer(my_peer_id)
			GlobalLogger.logs("Disconnected from session '%s'." % id, Enum.LogLevel.DEBUG)


	scene_m.set_active_session(get_connected_sessions()[0].id)

	scene_m.stop_master_scene(id)
	scene_m.destroy_master_scene(id)

	_database.sessions_api.erase(id)
	_database.sessions.erase(id)

	GlobalLogger.logs("Successfully disconnected from session '%s' and cleaned up." % id, Enum.LogLevel.DEBUG)
	Events.emit_signal("session_left")
	return

func kick_player(server_id:String, peer_id: int, reason: String):
	GlobalLogger.logs("Kicking peer '%s' from '%s' for reason '%s'" % [peer_id, server_id, reason], Enum.LogLevel.DEBUG)
	var database_has_sessions_api: bool = _database.sessions_api.has(server_id)
	# TODO: Check if peer exists
	if database_has_sessions_api:
		var mp_api: SceneMultiplayer = _database.sessions_api.get(server_id)
		# TODO: Notify user of kick
		mp_api.disconnect_peer(peer_id)
	return

func get_connected_sessions():
	var result = []

	for session_id in _database.sessions.keys():
		result.append(_database.sessions[session_id].merged({"id": session_id}))

	return result

func set_active_session(id: String):
	if _database.sessions.has(id):
		GlobalLogger.logs("Tried to mark an invalid session as active: '%s'" % id, Enum.LogLevel.WARNING)
		return

	for session_id in _database.sessions.keys():
		_database.sessions[session_id].active = false

	_database.sessions[id].active = true
	scene_m.set_active_session(id)
	return

func _update_session_server_listing(session_info: Dictionary, session_server: String) -> Dictionary:
	var response_dict = {"ok": false, "error": null, "data": null}

	GlobalLogger.logs("Updating session '%s' to the server '%s'" % [session_info.id, session_server])
	var url = UrlParser.deconstruct("%s/api/v1/updateSession" % session_server)

	if url.ok != true:
		GlobalLogger.logs("Failed to deconstruct the URL '%s'. Error: '%s'" % [session_server, url.error])
		response_dict.error = url.error
		return response_dict

	url = url.data

	var _body = {
		"id": _database.sessions_id.get(session_info.id),
		"session_name": session_info.name,
		"session_description": session_info.description,
		"session_privacy": session_info.privacy,
	}

	var _update_response = await http.req(
		HTTPClient.Method.METHOD_POST,
		url.host,
		url.path,
		url.port,
		["Accept: application/json", "Content-Type: application/json", "x-api-key: %s" % GlobalAccount.dev_session_server_api_key],
		JSON.stringify(_body)
	)

	return response_dict

func _remove_session_from_server(server_id: String, session_server: String) -> Dictionary:
	var response_dict = {"ok": false, "error": null, "data": {}}
	var _full_url = "%s/api/v1/deleteSession" % session_server

	GlobalLogger.logs("Removing session '%s' to the server '%s'" % [server_id, session_server])
	var url = UrlParser.deconstruct(_full_url)

	if url.ok != true:
		GlobalLogger.logs("Failed to deconstruct the URL '%s'. Error: '%s'" % [_full_url, url.error])
		response_dict.error = url.error
		return response_dict

	url = url.data

	var _body = {
		"id": _database.sessions_id.get(server_id),
	}

	var _removal_response = await http.req(
		HTTPClient.Method.METHOD_DELETE,
		url.host,
		url.path,
		url.port,
		["Accept: application/json", "Content-Type: application/json", "x-api-key: %s" % GlobalAccount.dev_session_server_api_key],
		JSON.stringify(_body)
	)

	if _removal_response.ok:
		response_dict.ok = true
		response_dict.data = JSON.parse_string(_removal_response.body)
		return response_dict

	response_dict.error = _removal_response.error
	return response_dict

func _find_available_port(target_port: int = MINIMUM_INCREMENTAL_PORT) -> int:
	GlobalLogger.logs("Trying to find an available port starting at '%s'." % target_port)
	var _found_port = null
	var _is_found = false

	while _is_found == false:
		var port_available = !_is_port_in_use(target_port)
		if port_available:
			_found_port = target_port
			_is_found = true
			break
		target_port = target_port + 1

	GlobalLogger.logs("Port found: '%s'" % target_port)

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
	GlobalLogger.logs("Creating a heartbeat timer for server '%s'" % session_id)
	# FIXME: Hardcoded time for timer.
	var timer = get_tree().create_timer(20)

	_database.heartbeats[session_id] = timer

	timer.timeout.connect(_heartbeat_timer_timeout.bind(session_id, session_server_url))
	return

func _heartbeat_timer_timeout(session_id: String, session_server_url: String):
	GlobalLogger.logs("Sending a heartbeat for server '%s'" % session_id)
	if _database.heartbeats.has(session_id) == false:
		GlobalLogger.logs("Server '%s' does not exist anymore, not sending a heartbeat." % session_id)
		return

	_heartbeat_session(session_id, session_server_url)

	_create_heartbeat_timer(session_id, session_server_url)
	return

func _heartbeat_session(session_id: String, session_server_url: String) -> void:
	var _full_url = "%s/api/v1/heartbeatSession" % session_server_url
	var _url = UrlParser.deconstruct(_full_url)

	if _url.ok != true:
		GlobalLogger.logs("Failed to deconstruct the URL '%s'. Error: '%s'" % [_full_url, _url.error])
		return

	_url = _url.data
	var body = {"session_id": _database.sessions_id.get(session_id)}

	var response = await http.req(
		HTTPClient.Method.METHOD_POST,
		_url.host,
		_url.path,
		_url.port,
		["Accept: application/json", "Content-Type: application/json", "x-api-key: %s" % GlobalAccount.dev_session_server_api_key],
		JSON.stringify(body)
	)

	if response and response.get("ok"):
		GlobalLogger.logs("Heartbeat sent for session '%s'" % session_id)
	return

func _advertise_session(session_info: Dictionary, session_server: String) -> Dictionary:
	var response_dict = {"ok": false, "error": null, "data": null}
	GlobalLogger.logs("Advertising session '%s' to the server '%s'" % [session_info.id, session_server])
	var _full_url = "%s/api/v1/postSession" % session_server
	var url = UrlParser.deconstruct(_full_url)

	if url.ok != true:
		GlobalLogger.logs("Failed to deconstruct the URL '%s'. Error: '%s'" % [_full_url, url.error])
		response_dict.error = url.error
		return response_dict

	url = url.data

	var _body = {
		"session_name": session_info.name,
		"session_description": session_info.description,
		"session_privacy": session_info.privacy,
		"session_port": session_info.port,
	}

	var advertise_response = await http.req(
		HTTPClient.Method.METHOD_POST,
		url.host,
		url.path,
		url.port,
		["Accept: application/json", "Content-Type: application/json", "x-api-key: %s" % GlobalAccount.dev_session_server_api_key],
		JSON.stringify(_body)
	)

	# FIXME: What is this flow? This is bad?
	if advertise_response.ok != true:
		response_dict.error = advertise_response.error
		return response_dict

	advertise_response = JSON.parse_string(advertise_response.body)
	if advertise_response.ok == false:
		response_dict.error = advertise_response.error
		return response_dict

	advertise_response = advertise_response.data

	response_dict.ok = true
	response_dict.data = advertise_response
	return response_dict
