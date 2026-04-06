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
signal dash_session_changed(session_data: Dictionary)
signal dash_message_received(message: Dictionary)
signal dash_notification(notification: Dictionary)
signal dash_account_list_loaded(account_list: PackedStringArray)

signal instance_updated(instance: Dictionary)