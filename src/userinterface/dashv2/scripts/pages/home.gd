# --- License
# File: /client/src/userinterface/dashv2/scripts/pages/home.gd
# Project: OpenMinerva
# Created Date: 11 May 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Control

@onready var active_sessions_container = get_node("HBoxContainer/PanelContainer/MarginContainer/VBoxContainer")
@onready var template_account_session_listing = preload("res://userinterface/dashv2/partials/home_server_listing.tscn")
@onready var network_m = get_tree().current_scene.get_node("NetworkManager")
@onready var scene_m = get_tree().current_scene.get_node("SceneManager")


func _ready() -> void:
	Events.connect("session_joined", _show_joined_sessions)
	Events.connect("session_left", _show_joined_sessions)
	_show_joined_sessions()

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
