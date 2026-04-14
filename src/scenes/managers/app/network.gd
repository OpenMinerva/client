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

var n_c = preload("res://scripts/network/network_compression.gd").new()
var url_regex = RegEx.create_from_string("^(https?)://([^/:]+)(?::(\\d+))?(.*)$")

@onready var http = preload("res://scripts/network/http.gd").new()
@onready var scene_m = get_tree().current_scene.get_node("SceneManager")
@onready var rpc_lib = get_tree().current_scene.get_node("RpcManager")

var _database = {
	"heartbeats": {},
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
	if port == 0:
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

	# Create a new peer.
	var _mp_api = SceneMultiplayer.new()
	var _session_peer = ENetMultiplayerPeer.new()
	var _create_server_response = _session_peer.create_server(port, MAX_CLIENTS)
	_mp_api.multiplayer_peer = _session_peer

	_database.sessions_api.set(_scene, _mp_api)
	_database.sessions.set(_scene, _instance)

	if _create_server_response != OK:
		GlobalLogger.logs("Failed to start server. Error: '%s'" % _create_server_response, 1)
		response_dict.error = str(_create_server_response)
		# TODO: Destroy server scene
		return response_dict
	
	# Create server root scene.
	if root_scene:
		scene_m.set_master_root_from_program(_scene, root_scene)
	else:
		scene_m.set_master_root_from_program(_scene, Enum.BaseLevel.GRID)

	scene_m.start_master_scene(_scene)
	
	# DEV: Force spawn the host.

	scene_m.get_master_scene(_scene).get_node("PlayerManager").spawn_player(1)

	return response_dict

func stop_server(id: String):
	# Kick all players (Server closing). 
	# Turn off all join requests.
	# Destroy multiplayer api.
	# Stop all managers.
	# Destroy server master scene.
	return

func update_server(id: String, server_info: Dictionary):
	# Get server from database.
	# Validate server updated data.
	# Update the database entry.
	# Emit server updated event to the server.
	# If server is now public, and advertising is enabled, advertise to the session-server(s).
	# TODO: Get session_servers from client config
	# TODO: Get enabled session_servers from server config
	# TODO: For each enabled session_server:
	var advertise_response = await _advertise_session(server_info, "http://localhost:40500")

	# TODO: Get list of successful session advertisements, and start heartbeats.
	if advertise_response.ok == true:
		_create_heartbeat_timer(advertise_response.data.id)
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

func get_connected_sessions():
	var result = []

	for session_id in _database.sessions.keys():
		result.append(_database.sessions[session_id].merged({"id": session_id}))

	return result

func _find_available_port(target_port: int = 20205) -> int:
	GlobalLogger.logs("Trying to find an available port starting at '%s'." % target_port)
	var _found_port = null
	var _is_found = false

	while _is_found == false:
		var port_available = !_is_port_in_use(target_port)
		if port_available:
			_found_port = target_port
			_is_found = true

		target_port = target_port + 1

	GlobalLogger.logs("Port found: '%s'" % target_port)

	return _found_port

func _is_port_in_use(port: int) -> bool:
	var tcp_server = TCPServer.new()
	var err = tcp_server.listen(port, "*")

	if err == OK:
		tcp_server.stop()
		return false

	return true

func _create_heartbeat_timer(session_id: String):
	GlobalLogger.logs("Creating a heartbeat timer for server '%s'" % session_id)
	# FIXME: Hardcoded time for timer.
	var timer = get_tree().create_timer(20)

	_database.heartbeats[session_id] = timer

	timer.timeout.connect(_heartbeat_timer_timeout.bind(session_id))
	return

func _heartbeat_timer_timeout(session_id):
	GlobalLogger.logs("Sending a heartbeat for server '%s'" % session_id)
	if _database.heartbeats.has(session_id) == false:
		GlobalLogger.logs("Server '%s' does not exist anymore, not sending a heartbeat." % session_id)
		return

	_heartbeat_session(session_id)

	_create_heartbeat_timer(session_id)
	return

func _heartbeat_session(session_id: String):
	# FIXME: Hardcoded localhost link.
	var url_parts = UrlParser.deconstruct("http://localhost:40500/api/v1/heartbeatSession")
	url_parts = url_parts.data
	var body = {"session_id": session_id}
	
	var response = await http.req(
		HTTPClient.Method.METHOD_POST,
		url_parts.host,
		url_parts.path,
		url_parts.port,
		["Accept: application/json", "Content-Type: application/json", "x-api-key: %s" % GlobalAccount.dev_session_server_api_key],
		JSON.stringify(body)
	)

	if response and response.get("ok"):
		GlobalLogger.logs("Heartbeat sent for session '%s'" % session_id, 0)
	return

func _advertise_session(session_info: Dictionary, session_server: String) -> Dictionary:
	var response_dict = {"ok": false, "error": null, "data": null}
	GlobalLogger.logs("Advertising session '%s' to the server '%s'" % [session_info.id, session_server])
	var url = UrlParser.deconstruct("%s/api/v1/postSession" % session_server)
	# TODO: Error checking
	url = url.data

	var _body = {
		"session_name": session_info.id,
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
	if advertise_response.ok == false:
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
