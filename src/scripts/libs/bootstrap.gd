# --- License
# File: /client/src/scripts/libs/bootstrap.gd
# Project: OpenMinerva
# Created Date: 21 April 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Node

@onready var network_m = get_tree().current_scene.get_node("NetworkManager")


func _ready() -> void:
	NSB.init()
	Discord.set_enabled(true)
	return


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		GlobalLogger.log("Shutting down", Enum.LogLevel.INFO)

		# Shutdown / leave all servers.
		var _connected_servers: Array = network_m.get_connected_sessions()
		_connected_servers.reverse()

		for server in _connected_servers:
			if server.type == network_m.registry.SessionConnectionType.HOST:
				network_m.stop_server(server.id)
				continue
			if server.type == network_m.registry.SessionConnectionType.CLIENT:
				network_m.leave_server(server.id)
				continue

		await get_tree().process_frame

		get_tree().quit()
