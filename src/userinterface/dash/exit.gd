# --- License
# File: /client/src/userinterface/dash/exit.gd
# Project: OpenMinerva
# Created Date: 27 March 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License

extends Control
@onready var _cancel_button = get_node("VBoxContainer/HBoxContainer/Cancel")
@onready var _exit_button = get_node("VBoxContainer/HBoxContainer/Exit")

func _ready():
    _cancel_button.pressed.connect(_handle_cancel_pressed)
    _exit_button.pressed.connect(_handle_exit_pressed)
    return

func _handle_cancel_pressed():
    Events.emit_signal("dash_switch_tab", "Home")
    return

func _handle_exit_pressed():
    # TODO: Save?
    # TODO: Sync?
    # TODO: Validate database?
    # TODO: Prune cache?
    get_tree().quit()
    return