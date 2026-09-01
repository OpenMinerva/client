# --- License
# File: /client/src/userinterface/dash/scripts/pages/debug.gd
# Project: OpenMinerva
# Created Date: 14 May 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends "res://userinterface/dash/scripts/pages/left_nav_container.gd"


func _ready():
	super._ready()

	Events.dash_switch_tab.connect(_handle_page_opened)
	return


func _handle_page_opened(page_name) -> void:
	if page_name != "Debug":
		return
	return
