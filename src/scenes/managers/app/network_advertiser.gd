# --- License
# File: /client/src/scenes/managers/app/network_advertiser.gd
# Project: OpenMinerva
# Created Date: 21 August 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Node
## This file contains all of the session advertisement functionality for listing our session among session servers.

## The internal database for keeping track of open sessions.
var _open_sessions = []


## List a session with a given session server.
## [param session_info] contains the session database information.
## [param session_server_url] is the target session server to list the session with.
func create_session(session_info: Dictionary, session_server_url: String) -> String:
	GlobalLogger.log("Attempting to list session '%s' to session server '%s'." % [session_info.id, session_server_url], Enum.LogLevel.INFO)

	var _full_url = "%s/api/v1/postSession" % session_server_url
	var _request_url = UrlParser.deconstruct(_full_url)

	if _request_url.ok != true:
		GlobalLogger.log("'%s' is not a valid URL." % _request_url, Enum.LogLevel.WARNING)
		return ""

	var _deconstructed_url: Dictionary = _request_url.data
	var _api_key = Accounts.get_session_server_token(_deconstructed_url.host)
	if _api_key == "":
		GlobalLogger.log("Could not get our account server token.", Enum.LogLevel.INFO)
		return ""

	var _body = {
		"session_name": session_info.name,
		"session_description": session_info.description,
		"session_privacy": session_info.privacy,
		"session_port": session_info.port,
	}

	var _advertise_response = await HTTP.req(
		HTTPClient.Method.METHOD_POST,
		_deconstructed_url.host,
		_deconstructed_url.path,
		_deconstructed_url.port,
		["Accept: application/json", "Content-Type: application/json", "x-api-key: %s" % _api_key],
		JSON.stringify(_body),
	)

	if _advertise_response.ok != true:
		GlobalLogger.log("Request to session server '%s' failed." % session_server_url, Enum.LogLevel.INFO)
		return ""

	var _advertise_response_json = JSON.parse_string(_advertise_response.body)
	if _advertise_response_json == null:
		GlobalLogger.log("Failed to parse listing response. Unknown error.", Enum.LogLevel.ERROR)
		GlobalLogger.log(_advertise_response_json, Enum.LogLevel.ERROR)
		return ""

	if _advertise_response_json.ok == false:
		GlobalLogger.log("Failed to list session.", Enum.LogLevel.ERROR)
		GlobalLogger.log(_advertise_response_json, Enum.LogLevel.ERROR)
		return ""

	var _session_key = _advertise_response_json.data.id
	_open_sessions.append(_session_key)
	_create_heartbeat(_session_key, session_server_url, 20)
	return _session_key


## Updates a session listing with a target session server.
## [param session_info] is a dictionary containing all of the information about our server.
## [param session_key] is the session key we were given with our listing to the session server.
## [param session_server_url] is the target session server url.
func update_session(session_info: Dictionary, session_key: String, session_server_url: String) -> void:
	GlobalLogger.log("Attempting to update session '%s' with server '%s'" % [session_info.id, session_server_url], Enum.LogLevel.INFO)

	var _request_url: Dictionary = UrlParser.deconstruct("%s/api/v1/updateSession" % session_server_url)
	if _request_url.ok != true:
		GlobalLogger.log("'%s' is not a valid URL." % _request_url, Enum.LogLevel.WARNING)
		return

	var _deconstructed_url: Dictionary = _request_url.data
	var _api_key: String = Accounts.get_session_server_token(_deconstructed_url.host)
	var _body = {
		"id": session_key,
		"session_name": session_info.name,
		"session_description": session_info.description,
		"session_privacy": session_info.privacy,
	}

	var _update_response = await HTTP.req(
		HTTPClient.Method.METHOD_POST,
		_deconstructed_url.host,
		_deconstructed_url.path,
		_deconstructed_url.port,
		["Accept: application/json", "Content-Type: application/json", "x-api-key: %s" % _api_key],
		JSON.stringify(_body),
	)

	if _update_response.ok != true:
		GlobalLogger.log("Request to session server '%s' failed." % session_server_url, Enum.LogLevel.INFO)
		return

	var _update_response_json = JSON.parse_string(_update_response.body)
	if _update_response_json == null:
		GlobalLogger.log("Failed to parse update response. Unknown error.", Enum.LogLevel.ERROR)
		GlobalLogger.log(_update_response_json, Enum.LogLevel.ERROR)
		return

	if _update_response_json.ok == false:
		GlobalLogger.log("Failed to update session.", Enum.LogLevel.ERROR)
		GlobalLogger.log(_update_response_json, Enum.LogLevel.ERROR)
		return

	return


## Delist a given session from a session server.
## [param session_id] is the session id of the session we are wanting to delist. This is only used for logging purposes.
## [param session_key] is our private session server key we were given when we originally listed the session to the server.
## [param session_server_url] is the url for the session server.
func destroy_session(session_id: String, session_key: String, session_server_url: String) -> bool:
	var _full_url = "%s/api/v1/deleteSession" % session_server_url
	GlobalLogger.log("Attempting to remove session '%s' from the server '%s'" % [session_id, session_server_url], Enum.LogLevel.INFO)

	var _request_url = UrlParser.deconstruct(_full_url)

	if _request_url.ok != true:
		GlobalLogger.log("'%s' is not a valid URL." % _request_url, Enum.LogLevel.WARNING)
		return false

	var _deconstructed_url: Dictionary = _request_url.data
	var _api_key = Accounts.get_session_server_token(_deconstructed_url.host)
	var _body = {
		"id": session_key,
	}
	var _removal_response = await HTTP.req(
		HTTPClient.Method.METHOD_DELETE,
		_deconstructed_url.host,
		_deconstructed_url.path,
		_deconstructed_url.port,
		["Accept: application/json", "Content-Type: application/json", "x-api-key: %s" % _api_key],
		JSON.stringify(_body),
	)

	if _removal_response.ok == true:
		GlobalLogger.log("Successfully removed listing '%s' from session server '%s'." % [session_id, session_server_url], Enum.LogLevel.INFO)
		var _listing_index: int = _open_sessions.find(session_key)
		_open_sessions.remove_at(_listing_index)

		return true

	GlobalLogger.log("Unknown error removing listing '%s' from session server '%s'." % [session_id, session_server_url], Enum.LogLevel.ERROR)
	GlobalLogger.log(_removal_response, Enum.LogLevel.ERROR)
	return false


func _create_heartbeat(session_key: String, session_server_url: String, seconds_interval: int = 20) -> void:
	GlobalLogger.log("Creating a heartbeat timer for '%s'" % session_server_url)

	var _timer = get_tree().create_timer(seconds_interval)
	_timer.timeout.connect(_heartbeat_timeout.bind(session_key, session_server_url))
	return


func _heartbeat_timeout(session_key: String, session_server_url: String) -> void:
	if _open_sessions.has(session_key) == false:
		GlobalLogger.log("Session was removed from open sessions, not sending a heartbeat.")
		return

	_send_heartbeat(session_key, session_server_url)
	_create_heartbeat(session_key, session_server_url, 20)
	return


func _send_heartbeat(session_key: String, session_server_url: String) -> void:
	var _request_url: Dictionary = UrlParser.deconstruct("%s/api/v1/heartbeatSession" % session_server_url)
	if _request_url.ok != true:
		GlobalLogger.log("'%s' is not a valid URL." % _request_url, Enum.LogLevel.WARNING)
		return

	var _deconstructed_url = _request_url.data
	var _api_key: String = Accounts.get_session_server_token(_deconstructed_url.host)
	var _body = { "session_id": session_key }

	var _heartbeat_response = await HTTP.req(
		HTTPClient.Method.METHOD_POST,
		_deconstructed_url.host,
		_deconstructed_url.path,
		_deconstructed_url.port,
		["Accept: application/json", "Content-Type: application/json", "x-api-key: %s" % _api_key],
		JSON.stringify(_body),
	)

	if _heartbeat_response == null:
		GlobalLogger.log("Failed to get a valid response for sending a heartbeat.", Enum.LogLevel.ERROR)
		return

	if _heartbeat_response.ok == true:
		GlobalLogger.log("Successfully sent heartbeat to '%s'" % session_server_url)
		return

	return
