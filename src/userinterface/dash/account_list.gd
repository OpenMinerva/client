# --- License
# File: /client/src/userinterface/dash/account_list.gd
# Project: OpenMinerva
# Created Date: 28 March 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License

extends Control

@onready var _account_template = get_node("Templates/Account")
@onready var _account_list = get_node("List/ScrollContainer/AccountList")
@onready var _create_account_button = get_node("List/HBoxContainer/NewAccount")

func _ready():
	_display_account_lists()
	_create_account_button.pressed.connect(Events.emit_signal.bind("dash_switch_tab", "AccountCreate"))
	return

func _clear_account_listings() -> void:
	for child in _account_list.get_children():
		child.queue_free()
	return

func _display_account_lists() -> void:
	var _list = GlobalAccount.get_all()

	if len(_list) == 0:
		GlobalLogger.logs("No accounts to display.")
		return

	for account in _list:
		var _account_listing = _account_template.duplicate()

		var _username_node = _account_listing.get_node("MarginContainer/HBoxContainer/VBoxContainer/Username")
		var _account_server_node = _account_listing.get_node("MarginContainer/HBoxContainer/VBoxContainer/AccountServer")
		var _login_button = _account_listing.get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Login")
		var _configure_button = _account_listing.get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Configure")
		var _remove_button = _account_listing.get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Remove")

		_account_list.add_child(_account_listing)
		GlobalLogger.logs("Added account '%s' to the login list." % _account_listing.id)
	return