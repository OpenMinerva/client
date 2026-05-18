# --- License
# File: /client/src/userinterface/dash/scripts/pages/assets.gd
# Project: OpenMinerva
# Created Date: 11 May 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends "res://userinterface/dash/scripts/pages/left_nav_container.gd"


func _ready():
	super._ready()

	Events.dash_switch_tab.connect(_handle_switch_tab)

	return


func _handle_switch_tab(tab_name) -> void:
	return
