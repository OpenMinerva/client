# --- License
# File: /client/src/scripts/signal_bus.gd
# Project: OpenMinerva
# Created Date: 28 March 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Node

# Dashboard
@warning_ignore("unused_signal")
signal dash_set_state(is_open: bool)
@warning_ignore("unused_signal")
signal dash_switch_tab(page_name: String)
@warning_ignore("unused_signal")
signal dash_active_account_changed(account: Dictionary)
@warning_ignore("unused_signal")
signal dash_storage_changed(storage_data: Dictionary)
@warning_ignore("unused_signal")
signal dash_session_changed(session_data: Dictionary)
@warning_ignore("unused_signal")
signal dash_message_received(message: Dictionary)
@warning_ignore("unused_signal")
signal dash_notification(notification: Dictionary)
@warning_ignore("unused_signal")
signal dash_account_list_loaded(account_list: PackedStringArray)
# Debug
@warning_ignore("unused_signal")
signal debug_entity_set_state()
# Settings
@warning_ignore("unused_signal")
signal dash_settings_updated()
# Instance
@warning_ignore("unused_signal")
signal instance_updated(instance: Dictionary)
@warning_ignore("unused_signal")
signal instance_root_changed(instance: Dictionary)
# Client Edit Mode
@warning_ignore("unused_signal")
signal cem_set_state(is_open: bool)
@warning_ignore("unused_signal")
signal cem_set_gizmo_state(state: bool)
# Multiplayer
@warning_ignore("unused_signal")
signal session_joined(instance: Dictionary)
@warning_ignore("unused_signal")
signal session_left(instance: Dictionary)
