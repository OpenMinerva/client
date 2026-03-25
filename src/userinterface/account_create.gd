# --- License
# File: /client/src/userinterface/account_create.gd
# Project: OpenMinerva
# Created Date: 27 February 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License

extends Node

var rsa = preload("res://scripts/crypto/rsa.gd").new()
var http = preload("res://scripts/network/http.gd").new()
var random = preload("res://scripts/utils/random.gd").new()

var root

var username_form_node
var password_form_node
var account_server_form_node
var remember_me_form_node
var local_account_form_node

var login_page_selectmethod
var login_page_usernamepassword
var login_page_oauth

const ACCOUNT_DATABASE_DIRECTORY = "user://config/accounts/accounts_db.cfg"

func init(caller_node: Node) -> void:
	root = caller_node.get_tree().current_scene.get_node("Hud/MarginContainer/VBoxContainer/Master/AccountCreate")
	
	username_form_node = root.get_node("Create/UsernamePassword/Create/VBoxContainer/CAUsername")
	password_form_node = root.get_node("Create/UsernamePassword/Create/VBoxContainer2/CAPassword")
	account_server_form_node = root.get_node("Create/UsernamePassword/Create/VBoxContainer3/CAAccountServer")
	remember_me_form_node = root.get_node("Create/UsernamePassword/Create/CARememberMe")
	local_account_form_node = root.get_node("Create/UsernamePassword/Create/CALocalAccount")

	login_page_selectmethod = root.get_node("Create/SelectMethod")
	login_page_usernamepassword = root.get_node("Create/UsernamePassword")

	login_page_oauth = root.get_node("Create/OAuth")

	# Select method
	login_page_selectmethod.get_node("Container/OAuth").pressed.connect(_open_page.bind("oauth"))
	login_page_selectmethod.get_node("Container/UsernamePassword").pressed.connect(_open_page.bind("usernamepassword"))
	return

func clear_form() -> void:
	username_form_node.text = ""
	password_form_node.text = ""
	account_server_form_node.text = ""

	remember_me_form_node.button_pressed = false
	local_account_form_node.button_pressed = false
	return

func create_account() -> void:
	# TODO: Check to see if ID exists already
	var _local_id = random.random_string(6, true)
	var _device_keys = rsa.generate_keypair(0)

	if !username_form_node.text:
		GlobalLogger.logs("No username provided for account, not creating an account.", 1)
		return

	if !local_account_form_node.button_pressed && (!password_form_node.text || !username_form_node.text):
		GlobalLogger.logs("Missing username or password from a non local account, not creating account.", 1)
		return

	GlobalLogger.logs("Creating an account configuration file: '%s'" % username_form_node.text, 1)
	GlobalLogger.logs("username: '%s', account_server: '%s', remember_me: '%s', local_account: '%s'" % [username_form_node.text, account_server_form_node.text, remember_me_form_node.button_pressed, local_account_form_node.button_pressed])

	var _account_dictionary = {
		"id": _local_id,
		"username": username_form_node.text,
		"account_server": account_server_form_node.text,
		"remember_me": remember_me_form_node.button_pressed,
		"local_account": local_account_form_node.button_pressed,
		"private_device_key": _device_keys.private,
		"public_device_key": _device_keys.public,
		"private_account_server_jwt": {"token": "", "expires": 0},
		"public_account_server_passport": {"token": "", "expires": 0}
	}
	GlobalAccount.create(_account_dictionary)

	if local_account_form_node.button_pressed == false && account_server_form_node.text != "":
		await GlobalAccount.authenticate(_local_id, password_form_node.text, remember_me_form_node.button_pressed)

	return

# Navigation
func _open_page(name: String) -> void:
	var valid_pages = []
	for child in root.get_node("Create").get_children():
		child.visible = false
		valid_pages.append(child.name.to_lower())

	if name not in valid_pages:
		GlobalLogger.logs("Tried to open a login page that does not exist.", 0)
		return

	match name:
		"usernamepassword":
			login_page_usernamepassword.visible = true
		"oauth":
			login_page_oauth.visible = true
		_:
			GlobalLogger.logs("Unknown error trying to open login page.", 0)
			reset_root()
	return

func reset_root() -> void:
	if !login_page_usernamepassword:
		GlobalLogger.logs("Tried to reset the root before initialization!", 3)
		return

	login_page_usernamepassword.visible = false
	login_page_oauth.visible = false
	login_page_selectmethod.visible = true
	return
