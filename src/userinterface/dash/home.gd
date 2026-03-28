# --- License
# File: /client/src/userinterface/dash/home.gd
# Project: OpenMinerva
# Created Date: 27 March 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License

extends Control

@onready var account_card_container = get_node("HBoxContainer/VBoxContainer/AccountDisplay")
@onready var storage_card_container = get_node("HBoxContainer/VBoxContainer/StorageDisplay")
@onready var session_card_container = get_node("HBoxContainer/VBoxContainer3/SessionDisplay")

func _ready():
	account_card_container.get_node("Button").pressed.connect(Events.emit_signal.bind("dash_switch_tab", "AccountDisplay"))
	
	Events.connect("dash_active_account_changed", _handle_active_account_changed)
	Events.connect("dash_storage_changed", _handle_storage_changed)
	Events.connect("dash_session_changed", _handle_session_changed)
	
	return

func _handle_active_account_changed(account: Dictionary) -> void:
	account_card_container.get_node("MarginContainer/HBoxContainer/VBoxContainer/Username").text = account.username
	account_card_container.get_node("MarginContainer/HBoxContainer/VBoxContainer/AccountServer").text = account.account_server
	return

func _handle_storage_changed(storage_data: Dictionary) -> void:
	storage_card_container.get_node("MarginContainer/VBoxContainer/ProgressBar").value = storage_data.used_percent
	storage_card_container.get_node("MarginContainer/VBoxContainer/Label2").text = "%s GiB used of %s GiB" % [storage_data.used_gigs, storage_data.total_gigs]
	return

func _handle_session_changed(session_data: Dictionary) -> void:
	session_card_container.get_node("MarginContainer/HBoxContainer/VBoxContainer/SessionName").text = session_data.session_name
	return
