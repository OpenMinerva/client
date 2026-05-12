# --- License
# File: /client/src/userinterface/dash/account_create.gd
# Project: OpenMinerva
# Created Date: 28 March 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Control

var _page_names = []

@onready var create = get_node("Create")
@onready var select_oauth_btn = get_node("Create/SelectMethod/Container/OAuth")
@onready var create_oauth_btn = get_node("Create/OAuth/Create/HBoxContainer/ConfirmCreateAccount")
@onready var create_oauth_back_btn = get_node("Create/OAuth/Create/HBoxContainer/CreateAccountBack")


func _ready():
	_get_pages()
	select_oauth_btn.pressed.connect(_display_login_route.bind("OAuth"))

	create_oauth_btn.pressed.connect(_create_oauth)
	create_oauth_back_btn.pressed.connect(_display_login_route.bind("SelectMethod"))
	return


func _display_oauth():
	return


func _display_login_route(page_name: String):
	if page_name not in _page_names:
		GlobalLogger.log("Tried to display an invalid login route.", Enum.LogLevel.WARNING)
		return

	for page in create.get_children():
		if page.name == page_name:
			page.visible = true
			continue

		page.visible = false
	return


func _get_pages() -> void:
	for page in create.get_children():
		_page_names.append(page.name)
	return


func _create_oauth() -> void:
	var display_name = get_node("Create/OAuth/Create/VBoxContainer3/CADisplayName").text
	var account_server = get_node("Create/OAuth/Create/VBoxContainer3/CAAccountServer").text

	var account = {
		"display_name": display_name,
		"account_server": account_server,
	}

	GlobalAccount.create(account, "oauth")

	Events.emit_signal("dash_switch_tab", "AccountDisplay")

	return
