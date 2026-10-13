# --- License
# File: /client/src/scripts/libs/bootstrap.gd
# Project: OpenMinerva
# Created Date: 21 April 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Node

var quit_action: Callable = func(): get_tree().quit()

@onready var network_m = get_tree().root.find_child("AppNetworkManager", true, false)


func _ready() -> void:
	NSB.init()
	Discord.set_enabled(true)
	return


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if network_m == null:
			# FIXME: gdUnit4 sometimes does not register AppNetworkManager correctly sometimes.
			network_m = get_tree().root.find_child("AppNetworkManager", true, false)

		GlobalLogger.log("Shutting down", Enum.LogLevel.INFO)
		StateManager.app_closing = true

		await _cleanup()
		quit_action.call()


func _cleanup() -> void:
	var _connected_sessions: Array = network_m.registry.get_all()
	_connected_sessions.reverse()

	for session in _connected_sessions:
		if session.type == network_m.registry.SessionConnectionType.HOST:
			network_m.stop_session(session.id)
			continue
		if session.type == network_m.registry.SessionConnectionType.CLIENT:
			network_m.leave_session(session.id)
			continue

	await get_tree().process_frame

	return
