# --- License
# File: /client/src/scripts/libs/bootstrap.gd
# Project: OpenMinerva
# Created Date: 21 April 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License

extends Node

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		GlobalLogger.logs("Shutting down", 0)
		get_tree().quit()
