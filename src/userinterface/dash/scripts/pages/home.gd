# --- License
# File: /client/src/userinterface/dash/scripts/pages/home.gd
# Project: OpenMinerva
# Created Date: 11 May 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Control

@onready var active_sessions_container = get_node("HBoxContainer/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer")
@onready var template_account_session_listing = preload("res://userinterface/dash/partials/home_server_listing.tscn")
@onready var network_m = get_tree().current_scene.get_node("NetworkManager")
@onready var scene_m = get_tree().current_scene.get_node("SceneManager")
@onready var dashboard = get_tree().current_scene.get_node("Dashboard")


func _ready() -> void:
	Events.connect("session_joined", _show_joined_sessions)
	Events.connect("session_left", _show_joined_sessions)
	_show_joined_sessions()

	get_node("%CreateNewWorld").clicked.connect(_on_create_new_world_button_pressed)
	dashboard.get_node("NewWorld").get_node("%Create").clicked.connect(_on_start_world)

	return


func _show_joined_sessions() -> void:
	var _sessions = network_m.get_connected_sessions()

	# Remove existing server listings
	for node in active_sessions_container.get_children():
		node.queue_free()

	# Add listings to the container
	for session in _sessions:
		var _entry = template_account_session_listing.instantiate()
		var _entry_label = _entry.get_node("MarginContainer/HBoxContainer/VBoxContainer/Label")
		var _entry_close = _entry.get_node("MarginContainer/HBoxContainer/AspectRatioContainer/Button")

		_entry_label.text = session.id
		_entry.pressed.connect(scene_m.set_active_session.bind(session.id))
		_entry_close.pressed.connect(network_m.leave_server.bind(session.id))
		active_sessions_container.add_child(_entry)
	return

func _on_create_new_world_button_pressed() -> void:
	dashboard.get_node("NewWorld").visible = true
	return


func _on_start_world() -> void:
	var _world_name: String = dashboard.get_node("NewWorld/BackgroundColor/MarginContainer/VBoxContainer/VBoxContainer/WorldNameVal").text
	var _world_base: Enum.BaseLevel = dashboard.get_node("NewWorld/BackgroundColor/MarginContainer/VBoxContainer/VBoxContainer/BaseVal").selected
	var _world_privacy: Enum.PrivacyLevel = dashboard.get_node("NewWorld/BackgroundColor/MarginContainer/VBoxContainer/VBoxContainer/PrivacyVal").selected

	network_m.start_server(0, _world_base)
	_show_joined_sessions()

	# HACK: For some reason, the active session does not properly get updated normally.
	var _sessions: Array = network_m.get_connected_sessions()
	scene_m.set_active_session(_sessions.back().name)
	return
