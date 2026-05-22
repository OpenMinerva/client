# --- License
# File: /client/src/userinterface/debug/scripts/entity_menu.gd
# Project: OpenMinerva
# Created Date: 21 May 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Control


func _ready() -> void:
	Events.debug_entity_set_state.connect(_toggle_state)
	return


func _toggle_state() -> void:
	visible = !visible
	return
