# --- License
# File: /client/src/userinterface/dashv2/scripts/pages/account_creation.gd
# Project: OpenMinerva
# Created Date: 07 May 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License

extends Control

@onready var _username_node: Control = get_node("HBoxContainer/VBoxContainer/ScrollContainer/VBoxContainer/Username")
@onready var _username_lineedit_node: Control = _username_node.get_node("PanelContainer/MarginContainer/HBoxContainer/MarginContainer/LineEdit")
@onready var _account_server_node: Control = get_node("HBoxContainer/VBoxContainer/ScrollContainer/VBoxContainer/AccountServer")
@onready var _account_server_lineedit_node: Control = _account_server_node.get_node("PanelContainer/MarginContainer/HBoxContainer/MarginContainer/LineEdit")

@onready var _accept_button: Button = get_node("HBoxContainer/VBoxContainer/Accept/Button")

func _ready():
	_accept_button.pressed.connect(_create_account)
	return

func _create_account() -> void:
	var _username: String = _username_lineedit_node.text
	var _account_server: String = _account_server_lineedit_node.text
	var _account_data: Dictionary = {}
	var _create_account_response: Dictionary = {}
	var _account_id: String = ""
	
	_account_data.set("display_name", _username)
	_account_data.set("account_server", _account_server)

	_create_account_response = GlobalAccount.create(_account_data, "oauth")
	_account_id = _create_account_response.get("id")
	GlobalAccount.use(_account_id)
	return