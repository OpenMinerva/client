# --- License
# File: /client/src/userinterface/dash/home.gd
# Project: OpenMinerva
# Created Date: 27 March 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License

extends Control

@onready var network_m = get_tree().current_scene.get_node("NetworkManager")
@onready var scene_m = get_tree().current_scene.get_node("SceneManager")

@onready var account_card_container = get_node("HBoxContainer/VBoxContainer/AccountDisplay")
@onready var storage_card_container = get_node("HBoxContainer/VBoxContainer/StorageDisplay")
@onready var active_sessions_container = get_node("HBoxContainer/VBoxContainer/ActiveSessions")
@onready var session_card_container = get_node("HBoxContainer/VBoxContainer3/SessionDisplay")

@onready var active_session_template = get_node("Templates/ActiveSessionButton")

func _ready():
	account_card_container.get_node("Button").pressed.connect(Events.emit_signal.bind("dash_switch_tab", "AccountDisplay"))
	
	Events.connect("dash_active_account_changed", _handle_active_account_changed)
	Events.connect("dash_storage_changed", _handle_storage_changed)
	Events.connect("dash_session_changed", _handle_session_changed)
	Events.connect("dash_session_changed", _handle_session_changed)

	Events.connect("session_joined", _display_active_sessions)

	_display_active_sessions()
	
	return

func _handle_active_account_changed(account: Dictionary) -> void:
	account_card_container.get_node("MarginContainer/HBoxContainer/VBoxContainer/Username").text = account.get("username") if account.get("username") else account.get("display_name")
	account_card_container.get_node("MarginContainer/HBoxContainer/VBoxContainer/AccountServer").text = account.account_server
	return

func _handle_storage_changed(storage_data: Dictionary) -> void:
	storage_card_container.get_node("MarginContainer/VBoxContainer/ProgressBar").value = storage_data.used_percent
	storage_card_container.get_node("MarginContainer/VBoxContainer/Label2").text = "%s GiB used of %s GiB" % [storage_data.used_gigs, storage_data.total_gigs]
	return

func _handle_session_changed(session_data: Dictionary) -> void:
	session_card_container.get_node("MarginContainer/HBoxContainer/VBoxContainer/SessionName").text = session_data.session_name
	return

func _display_active_sessions() -> void:
	for node in active_sessions_container.get_node("MarginContainer/VBoxContainer").get_children():
		if node is Button:
			node.queue_free()

	var _sessions = network_m.get_connected_sessions()

	for session in _sessions:
		var _entry = active_session_template.duplicate()
		_entry.text = session.id
		_entry.pressed.connect(scene_m.set_active_session.bind(session.id))
		active_sessions_container.get_node("MarginContainer/VBoxContainer").add_child(_entry)

	# TODO: When button is pressed, focus that session
	return
