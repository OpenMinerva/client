extends Node

var rsa = preload("res://scripts/crypto/rsa.gd").new()
var http = preload("res://scripts/network/http.gd").new()
var random = preload("res://scripts/utils/random.gd").new()

enum _message_type {NORMAL, ERROR, SUCCESS}

var _account_config: Variant
var current_account = {"username": "", "public_account_server_passport": ""}

func _ready():
	await _maybe_create_account_database_config_file()
	_account_config = await FileManager.read_config_file("accounts", "accounts_db.cfg")
	_get_account_list()
	pass

func _get_account_list():
	_delete_all_accounts_in_account_list()
	for id in _account_config.get_sections():
		_display_account_in_available_account_list(id)
	return

func _display_account_in_available_account_list(id):
	var account_username = _account_config.get_value(id, "username", "Anonymous")
	var account_account_server = _account_config.get_value(id, "account_server", "Local Account")

	var account_button = get_node("Templates/AccountListSelection").duplicate()

	account_button.get_node("HBoxContainer/VBoxContainer/Username").text = account_username
	account_button.get_node("HBoxContainer/VBoxContainer/AccountServer").text = account_account_server if account_account_server != "" else "Local Account"
	account_button.get_node("HBoxContainer/DeleteEntry").pressed.connect(_delete_account.bind(id))
	account_button.pressed.connect(_login_to_account.bind(id))

	get_node("Panel/AccountList/VBoxContainer/ScrollContainer/VBoxContainer").add_child(account_button)
	account_button.visible = true
	return

func _delete_all_accounts_in_account_list() -> void:
	for listing in get_node("Panel/AccountList/VBoxContainer/ScrollContainer/VBoxContainer").get_children():
		listing.queue_free()
	return

func _delete_account(section_id: String) -> void:
	GlobalLogger.logs("Deleting account '%s'" % section_id)
	_account_config.erase_section(section_id)
	_account_config.save("user://config/accounts/accounts_db.cfg")
	return

func _create_account(username: String, password: String = "", account_server: String = "", remember_me: bool = false, local_account: bool = false):
	GlobalLogger.logs("Creating an account configuration file: '%s'" % username, 1)
	GlobalLogger.logs("username: '%s', password: '%s', account_server: '%s', remember_me: '%s', local_account: '%s'" % [username, password, account_server, remember_me, local_account])

	# TODO: Check to see if ID exists
	var section_id = random.random_string()

	_account_config.set_value(section_id, "username", username)
	_account_config.set_value(section_id, "account_server", account_server)
	_account_config.set_value(section_id, "remember_me", remember_me)
	_account_config.set_value(section_id, "local_account", local_account)

	# TODO: Generate keys here.
	var device_keys = rsa.generate_keypair(0)

	_account_config.set_value(section_id, "private_account_server_jwt", "")
	_account_config.set_value(section_id, "private_device_key", device_keys.private)
	_account_config.set_value(section_id, "public_device_key", device_keys.public)
	_account_config.set_value(section_id, "public_account_server_passport", "")

	_account_config.save("user://config/accounts/accounts_db.cfg")

	if account_server != "" && local_account == false:
		_attempt_connection_to_account_server(section_id, username, password, account_server, remember_me)
	_get_account_list()
	return

func _attempt_connection_to_account_server(section_id: String, username: String, password: String, account_server: String = "", remember_me: bool = false):
	GlobalLogger.logs("Attempting to authorize the connection to the account server.")

	var data = {"username": username, "password": password}
	# var response = await http.req(HTTPClient.Method.METHOD_POST, account_server, "/api/v1/device/auth", 40400, ["Accept: application/json", "Content-Type: application/json"], JSON.stringify(data))
	var response = await http.req(HTTPClient.Method.METHOD_POST, account_server, "/api/v1/login", 40400, ["Accept: application/json", "Content-Type: application/json"], JSON.stringify(data))
	if response["ok"] == false:
		GlobalLogger.logs("Response failed for unknown reason.", 1)
		return

	if response["body"] == null:
		GlobalLogger.logs("No body provided for login request.", 3)
		return

	var res_body = JSON.parse_string(response["body"])

	if "error" in res_body.keys():
		GlobalLogger.logs("Login request returned an error. '%s'" % res_body["error"], 1)
		return
		
	var private_account_server_jwt = response["response_headers"]["Set-Cookie"].split("; ")
	private_account_server_jwt[0] = private_account_server_jwt[0].replace("token=", "")
	CredentialStore.set_account_credential(private_account_server_jwt)
	GlobalLogger.logs("Successfully received the JWT.")

	# TODO: Get public_account_server_passport from server.
	var device_response = await http.req(HTTPClient.Method.METHOD_POST, account_server, "/api/v1/device/auth", 40400, ["Accept: application/json", "Content-Type: application/json"], JSON.stringify(data))
	if device_response["ok"] == false:
		GlobalLogger.logs("Creating a device failed for unknown reason.", 1)
		return

	if device_response["body"] == null:
		GlobalLogger.logs("No body provided for device creation request.", 3)
		return

	var device_response_body = JSON.parse_string(device_response["body"])

	if "error" in device_response_body.keys():
		GlobalLogger.logs("Device creation request returned an error. '%s'" % res_body["error"], 1)
		return

	var public_account_server_passport = device_response["response_headers"]["Set-Cookie"].split("; ")
	public_account_server_passport = public_account_server_passport[0].replace("token=", "")

	if remember_me:
		_account_config.set_value(section_id, "private_account_server_jwt", private_account_server_jwt)
		_account_config.set_value(section_id, "public_account_server_passport", public_account_server_passport)
		_account_config.save("user://config/accounts/accounts_db.cfg")

	return

func _display_message(msg: String, type: _message_type):
	# TODO: Show message in line
	GlobalLogger.logs(msg, 1)
	return

func _maybe_create_account_database_config_file():
	# Check if file exists first.
	# If it does not exist, create an empty file.
	var config_file_exists = await FileAccess.file_exists("user://config/accounts/accounts_db.cfg")

	if config_file_exists == false:
		FileManager.create_config_file("accounts", "accounts_db.cfg")
	return

func _login_to_account(id: String) -> void:
	GlobalLogger.logs("Logging into '%s'" % id)
	var username = _account_config.get_value(id, "username")
	var public_account_server_passport = _account_config.get_value(id, "public_account_server_passport")
	CredentialStore.set_public_account_server_passport(public_account_server_passport)
	current_account = {"username": username, "public_account_server_passport": public_account_server_passport}

# Buttons:
# These just initiate the functions otherwise in this file
func _on_add_account_pressed():
	_change_primary_view("CreateLocalAccount")
	return

func _change_primary_view(target_node_name: String):
	for view in get_node("Panel").get_children():
		view.visible = false

	get_node("Panel/%s" % target_node_name).visible = true
	return

func _on_back_from_create_local_account_pressed():
	_change_primary_view("AccountList")
	# TODO: Clear line entries
	return

func _on_create_local_account_button_pressed():
	var username = get_node("Panel/CreateLocalAccount/VBoxContainer/CLAUsername").text
	var password = get_node("Panel/CreateLocalAccount/VBoxContainer/CLAPassword").text
	var account_server = get_node("Panel/CreateLocalAccount/VBoxContainer/CLAAccountServer").text
	var remember_me: bool = get_node("Panel/CreateLocalAccount/VBoxContainer/CLARememberMe").button_pressed
	var local_account: bool = get_node("Panel/CreateLocalAccount/VBoxContainer/CLALocalAccount").button_pressed

	_create_account(username, password, account_server, remember_me, local_account)
	return
