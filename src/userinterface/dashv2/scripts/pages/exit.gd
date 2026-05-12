# --- License
# File: /client/src/userinterface/dashv2/scripts/pages/exit.gd
# Project: OpenMinerva
# Created Date: 11 May 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Node

@onready var cancel_button: Button = get_node("VBoxContainer/HBoxContainer/Cancel")
@onready var exit_button: Button = get_node("VBoxContainer/HBoxContainer/Exit")


func _ready() -> void:
	cancel_button.pressed.connect(_cancel_exit)
	exit_button.pressed.connect(_exit)
	return


func _cancel_exit() -> void:
	Events.emit_signal("dash_switch_tab", "Home")
	return


func _exit() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	return
