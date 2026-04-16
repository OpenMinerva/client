# --- License
# File: /client/src/userinterface/dash/settings.gd
# Project: OpenMinerva
# Created Date: 27 March 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License

extends Control

@onready var _templates_session_server_listing = get_node("Templates/SessionServerListing")
@onready var _session_server_container = get_node("HBoxContainer/Container/Config/SessionServers/VBoxContainer/PanelContainer/MarginContainer2/ScrollContainer/MarginContainer/VBoxContainer")

func _ready():
	_load_session_servers()

	Events.dash_switch_tab.connect(_handle_page_opened)
	return

func _handle_page_opened(page_name) -> void:
	if page_name != "Settings":
		return

	_load_session_servers()
	return

func _load_session_servers() -> void:
	GlobalLogger.logs("Loading session servers.")
	var _servers = SettingsManager.get_session_servers()

	for _existing_listing in _session_server_container.get_children():
		_existing_listing.queue_free()

	for server in _servers:
		var _template = _templates_session_server_listing.duplicate()
		_template.get_node("Label").text = server.url
		_template.get_node("Remove").pressed.connect(_remove_session_server.bind(server.url))
		_session_server_container.add_child(_template)
	return

func _remove_session_server(url: String) -> void:
	SettingsManager.remove_session_server(url)
	_load_session_servers()