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


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		GlobalLogger.log("Shutting down")

		# Shutdown / leave all servers.
		for server in network_m.get_connected_sessions():
			if server.type == "host":
				network_m.stop_server(server.id)
				continue
			if server.type == "client":
				network_m.leave_server(server.id)
				continue

		get_tree().quit()
