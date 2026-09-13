# --- License
# File: /client/src/scenes/managers/app/network_registry.gd
# Project: OpenMinerva
# Created Date: 20 August 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Node
## This submodule contains the database in which sessions are officially registered with the client.

enum SessionConnectionType {
	HOST = 0,
	CLIENT = 1,
}

## Template used for session server key storage.
const SESSION_SERVER_KEY_TEMPLATE: Dictionary = {
	"url": "",
	"key": "",
}
## Template for sessions to store in the _database
const DATABASE_TEMPLATE: Dictionary = {
	"name": "",
	"description": "",
	"type": 0,
	"port": 0,
	"max_connected_users": 1,
	"privacy": null,
	"connected_players": [],
	"start_time": 0,
	"session_server_keys": [],
	"api": null,
	"networking": {
		"use_steam": false,
		"use_lan": false,
	},
}

## The internal database to store and keep track of the active and connected sessions.
var _database: Array[Dictionary] = []
## The order of the sessions. Normally used for when we disconnect from one session, and go to the previous in the stack.
var _session_stack: Array[String] = []


## Add a session to the registry
## [param name] is the name of the session.
## [param description] provides a description of the session.
## [param type] is whether we are a host or a client.
## [param port] contains the target port of the session.
## [param max_connected_users] is the maximum amount of connected peers to the session.
## [param privacy] sets the privacy of the session to the session servers.
## [param api] is the internal SceneMultiplayer API used for this session.
func add_session(session_name: String, description: String, _type: SessionConnectionType, port: int, max_connected_users: int, privacy: Enum.PrivacyLevel, api: SceneMultiplayer) -> void:
	var _session = DATABASE_TEMPLATE.duplicate(true)

	_session.id = session_name
	_session.name = session_name
	_session.description = description
	_session.port = port
	_session.max_connected_users = max_connected_users
	_session.privacy = privacy
	_session.api = api

	_database.append(_session)
	return


## Remove a session from our registry
## [param session_id] is the ID of the session to remove.
func remove_session(session_id: String) -> void:
	GlobalLogger.log("Removing session '%s' from registry." % session_id, Enum.LogLevel.DEBUG)

	var _index: int = _database.find_custom(func(entry): return entry.id == session_id)
	_database.remove_at(_index)

	var _stack_index: int = _session_stack.find(session_id)
	_session_stack.remove_at(_stack_index)

	GlobalLogger.log("Session '%s' removed from registry." % session_id, Enum.LogLevel.INFO)
	return


func update_players(_session_id: String, _players: Array[Dictionary]) -> void:
	GlobalLogger.log("'%s' is not implemented." % get_stack()[0]["function"], Enum.LogLevel.WARNING)
	return


## Returns true if we are connected to a session.
## [param session_id] is the ID of the session to remove.
func has_session(session_id: String) -> bool:
	var _index: int = _database.find_custom(func(entry): return entry.id == session_id)
	return _index >= 0


## Returns the session information of a session.
## [param session_id] is the ID of the session to inspect.
func get_session(session_id: String) -> Dictionary:
	var _index: int = _database.find_custom(func(entry): return entry.id == session_id)
	return _database[_index]


## Returns all of the connected sessions.
func get_all() -> Array[Dictionary]:
	return _database


## Returns all of the connected sessions, but only their ID.
func get_all_ids() -> Array[String]:
	var _all_ids: Array[String]

	for _session in _database:
		_all_ids.append(_session.local_id)

	return _all_ids


## Returns our peer ID for a connected session.
## [param session_id] is the ID of the session to get our ID from.
func get_peer_id(session_id: String) -> int:
	var _session: Dictionary = get_session(session_id)
	return _session.api.get_unique_id()


func set_recent(session_id: String) -> void:
	GlobalLogger.log("Setting session '%s' as recent." % session_id)
	if has_session(session_id) == false:
		GlobalLogger.log("Session '%s' did not exist, can not add it to the stack." % session_id)
		return

	if _session_stack.has(session_id) == true:
		var _index: int = _session_stack.find(session_id)
		_session_stack.remove_at(_index)

	_session_stack.push_front(session_id)
	return


func get_previous() -> String:
	GlobalLogger.log("Retreiving the previous session in the stack.")

	if _session_stack.size() > 1:
		return _session_stack[1]

	return ""


## Adds a session server private key to a database entry so that the app can publish and update information about the target session to that session server.
## [param session_id] is the ID of the session to add the key to.
## [param url] is the URL of the target session server.
## [param key] is the key provided by the session server to allow us to update the listing.
func add_session_server_key(session_id: String, url: String, key: String) -> void:
	# TODO: Create a Session Resource?
	GlobalLogger.log("Adding session server '%s' key to session '%s'" % [url, session_id])

	if has_session(session_id) == false:
		GlobalLogger.log("Could not add session server keys to '%s'. That server does not exist in our database.", Enum.LogLevel.WARNING)
		return

	var _session: Dictionary = get_session(session_id)

	if _session.session_server_keys.find_custom(func(pair): return pair.url == url) >= 0:
		GlobalLogger.log("Could not add session server keys to '%s'. We already have this session server set up with a key.", Enum.LogLevel.WARNING)
		return

	var _key_obj = SESSION_SERVER_KEY_TEMPLATE.duplicate(true)

	_key_obj.url = url
	_key_obj.key = key

	_session.session_server_keys.append(_key_obj)

	return
