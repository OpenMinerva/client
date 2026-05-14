# --- License
# File: /client/src/userinterface/dashv2/scripts/header.gd
# Project: OpenMinerva
# Created Date: 07 May 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Control

@onready var navigation_nodes: Array[Node] = get_node("MarginContainer/HBoxContainer").get_children()
@onready var header_account_button: Control = get_node("MarginContainer/HBoxContainer/AccountButton")
@onready var header_account_button_texture = header_account_button.get_node("Button/MarginContainer/HBox/TextureRect")
@onready var header_account_button_name = header_account_button.get_node("Button/MarginContainer/HBox/VBox/Name")
@onready var header_account_button_location = header_account_button.get_node("Button/MarginContainer/HBox/VBox/Location")


func _ready():
	Events.connect("dash_active_account_changed", _handle_active_account_changed)

	_setup_header_bar()
	return


func _setup_header_bar():
	header_account_button.get_node("Button").pressed.connect(Events.emit_signal.bind("dash_switch_tab", "_AccountSelection"))
	return


func _handle_active_account_changed(_account_id: String) -> void:
	GlobalLogger.log("Active account changed: '%s'" % _account_id)
	var _account = GlobalAccount.get_account(_account_id)
	# TODO: header_account_button_texture
	header_account_button_name.text = _account.display_name
	header_account_button_location.text = _account.account_server
