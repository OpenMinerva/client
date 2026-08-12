@warning_ignore("unused_signal")
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
signal dash_set_state(is_open: bool)
signal dash_switch_tab(page_name: String)
signal dash_active_account_changed(account: Dictionary)
signal dash_storage_changed(storage_data: Dictionary)
signal dash_session_changed(session_id: String)
signal dash_message_received(message: Dictionary)
signal dash_notification(notification: Dictionary)
signal dash_account_list_loaded(account_list: PackedStringArray)
# Debug
signal debug_entity_set_state()
# Settings
signal dash_settings_updated()
# Instance
signal instance_updated(instance: Dictionary)
signal instance_root_changed(instance: Dictionary)
# Client Edit Mode
signal cem_set_state(is_open: bool)
signal cem_set_gizmo_state(state: bool)
signal cem_camera_state(state: bool)
signal cem_camera_rotating(state: bool)
# Multiplayer
signal session_joined(instance: Dictionary)
signal session_left(instance: Dictionary)
# App
signal escape_mouse(mouse_is_visible: bool)
