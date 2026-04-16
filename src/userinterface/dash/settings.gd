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
@onready var _session_server_container = get_node("HBoxContainer/Container/Config/SessionServers/VBoxContainer/PanelContainer/MarginContainer2/VBoxContainer/ScrollContainer/MarginContainer/VBoxContainer")

@onready var _add_session_server_btn = get_node("HBoxContainer/Container/Config/SessionServers/VBoxContainer/PanelContainer/MarginContainer2/VBoxContainer/HBoxContainer/Button")
@onready var _add_session_server_name = get_node("HBoxContainer/Container/Config/SessionServers/VBoxContainer/PanelContainer/MarginContainer2/VBoxContainer/HBoxContainer/Name")
@onready var _add_session_server_url = get_node("HBoxContainer/Container/Config/SessionServers/VBoxContainer/PanelContainer/MarginContainer2/VBoxContainer/HBoxContainer/URL")

func _ready():
	_load_session_servers()

	_add_session_server_btn.pressed.connect(_add_session_server)

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

func _add_session_server() -> void:
	var _name = _add_session_server_name.text
	var _url = _add_session_server_url.text

	if _name == "":
		return

	if _url == "":
		return

	SettingsManager.add_session_server({"name": _name, "url": _url})

	_add_session_server_name.text = ""
	_add_session_server_url.text = ""
	_load_session_servers()
	return
