# --- License
# File: /client/src/userinterface/dashv2/scripts/pages/account_selection.gd
# Project: OpenMinerva
# Created Date: 07 May 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Control

@onready var template_account_listing: PackedScene = preload("res://userinterface/dashv2/partials/account_button_listing.tscn")
@onready var account_list_container: Control = $"HBoxContainer/VBoxContainer/ScrollContainer/VBoxContainer"
@onready var create_account_button: Control = $"HBoxContainer/VBoxContainer/NavButton/Button"


func _ready():
	Events.dash_account_list_loaded.connect(_populate_account_list)

	_populate_account_list()
	create_account_button.pressed.connect(Events.emit_signal.bind("dash_switch_tab", "_AccountCreation"))
	return


func _populate_account_list() -> void:
	const TEMPLATE_ACCOUNT_NAME_PATH = "HBoxContainer/Button/MarginContainer/HBox/VBox/Name"
	const TEMPLATE_ACCOUNT_DIRECTORY_PATH = "HBoxContainer/Button/MarginContainer/HBox/VBox/Location"
	const TEMPLATE_ACCOUNT_PICTURE_PATH = "HBoxContainer/Button/MarginContainer/HBox/TextureRect"
	const TEMPLATE_ACCOUNT_BUTTON_PATH = "HBoxContainer/Button"
	const TEMPLATE_ACCOUNT_CONFIGURE_BUTTON_PATH = "HBoxContainer/Configure/Button"
	const TEMPLATE_ACCOUNT_DELETE_BUTTON_PATH = "HBoxContainer/Delete/Button"

	GlobalLogger.log("Populating account list in '%s'." % name)
	var _accounts: Array[Dictionary] = GlobalAccount.get_all()

	# Remove existing listings
	for child: Control in account_list_container.get_children():
		child.queue_free()

	for _account: Dictionary in _accounts:
		var _template = template_account_listing.instantiate()
		var _name_node = _template.get_node(TEMPLATE_ACCOUNT_NAME_PATH)
		var _location_node = _template.get_node(TEMPLATE_ACCOUNT_DIRECTORY_PATH)
		var _picture_node = _template.get_node(TEMPLATE_ACCOUNT_PICTURE_PATH)
		var _button_node = _template.get_node(TEMPLATE_ACCOUNT_BUTTON_PATH)
		var _configure_node = _template.get_node(TEMPLATE_ACCOUNT_CONFIGURE_BUTTON_PATH)
		var _delete_node = _template.get_node(TEMPLATE_ACCOUNT_DELETE_BUTTON_PATH)

		# Set display visuals
		_name_node.text = _account.display_name
		_location_node.text = _account.account_server
		# TODO: _picture_node.texture = null

		# Add event listeners
		_button_node.pressed.connect(GlobalAccount.use.bind(_account.id))
		# TODO: _configure_node
		_delete_node.pressed.connect(GlobalAccount.remove.bind(_account.id))

		# Append
		account_list_container.add_child(_template)

		GlobalLogger.log("Added account '%s' to the list." % _account.id)
		continue
	return
