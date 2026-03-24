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

const ACCOUNT_DATABASE_DIRECTORY = "user://config/accounts/accounts_db.cfg"

func init(caller_node: Node) -> void:
	root = caller_node.get_tree().current_scene.get_node("Hud/MarginContainer/VBoxContainer/Master/AccountCreate")
	
	username_form_node = root.get_node("Create/MarginContainer/Create/VBoxContainer/CAUsername")
	password_form_node = root.get_node("Create/MarginContainer/Create/VBoxContainer2/CAPassword")
	account_server_form_node = root.get_node("Create/MarginContainer/Create/VBoxContainer3/CAAccountServer")
	remember_me_form_node = root.get_node("Create/MarginContainer/Create/CARememberMe")
	local_account_form_node = root.get_node("Create/MarginContainer/Create/CALocalAccount")
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
		await GlobalAccount.get_passport(_local_id)

	return
