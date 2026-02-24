extends Node

var rsa = preload("res://scripts/crypto/rsa.gd").new()
var http = preload("res://scripts/network/http.gd").new()
var random = preload("res://scripts/utils/random.gd").new()
var account_lib = preload("res://scripts/libs/account.gd").new()

const ACCOUNT_DATABASE_DIRECTORY = "user://config/accounts/accounts_db.cfg"

enum _message_type {NORMAL, ERROR, SUCCESS}

func _ready():
	await account_lib._load_account_database()
	_render_account_list()
	return

func _render_account_list():
	_clear_account_list()

	var _all_accounts: Array = await account_lib.get_all()

	for account in _all_accounts:
		_display_account_in_list(account)
	return

func _clear_account_list():
	var account_list_container_node = get_node("Panel/AccountList/VBoxContainer/ScrollContainer/VBoxContainer")

	for listing in account_list_container_node.get_children():
		listing.queue_free()
	return

func _display_account_in_list(account):
	var account_list_container_node = get_node("Panel/AccountList/VBoxContainer/ScrollContainer/VBoxContainer")

	# Duplicate the account button.
	var account_button = get_node("Templates/AccountListSelection").duplicate()
	account_button.get_node("HBoxContainer/VBoxContainer/Username").text = account.username
	account_button.get_node("HBoxContainer/VBoxContainer/AccountServer").text = account.account_server # if account.account_server != "" else "Local Account"
	account_button.get_node("HBoxContainer/DeleteEntry").pressed.connect(_delete_account.bind(account.id))
	account_button.pressed.connect(_login.bind(account.id))

	# Insert the account into our list.
	account_list_container_node.add_child(account_button)
	account_button.visible = true
	return

func _login(local_id: String):
	var _account_config = await FileManager.read_config_file("accounts", "accounts_db.cfg")

	var passport = _account_config.get_value(local_id, "public_account_server_passport")
	var private_account_server_jwt = _account_config.get_value(local_id, "private_account_server_jwt")

	CredentialStore.set_public_account_server_passport(passport)
	CredentialStore.set_private_account_server_jwt(private_account_server_jwt)
	return
	
func _delete_account(local_id: String):
	account_lib.remove(local_id)
	return

func _create_account() -> void:
	var _account_config = await FileManager.read_config_file("accounts", "accounts_db.cfg")

	var username = get_node("Panel/CreateLocalAccount/VBoxContainer/CLAUsername").text
	var password = get_node("Panel/CreateLocalAccount/VBoxContainer/CLAPassword").text
	var account_server = get_node("Panel/CreateLocalAccount/VBoxContainer/CLAAccountServer").text
	var remember_me: bool = get_node("Panel/CreateLocalAccount/VBoxContainer/CLARememberMe").button_pressed
	var local_account: bool = get_node("Panel/CreateLocalAccount/VBoxContainer/CLALocalAccount").button_pressed
	# TODO: Check to see if ID exists already
	var local_id = random.random_string()
	var device_keys = rsa.generate_keypair(0)

	GlobalLogger.logs("Creating an account configuration file: '%s'" % username, 1)
	GlobalLogger.logs("username: '%s', account_server: '%s', remember_me: '%s', local_account: '%s'" % [username, account_server, remember_me, local_account])

	var _account_dictionary = {
		"id": local_id,
		"username": username,
		"account_server": account_server,
		"remember_me": remember_me,
		"local_account": local_account,
		"private_device_key": device_keys.private,
		"public_device_key": device_keys.public,
		"private_account_server_jwt": "",
		"public_account_server_passport": ""
	}
	
	_account_config.save(ACCOUNT_DATABASE_DIRECTORY)
	account_lib.create(_account_dictionary)

	if local_account == false && account_server != "":
		account_lib.authenticate(local_id, password, remember_me)
		# _connect_to_account_server(local_id, username, password, account_server, device_keys.public, remember_me)

	_render_account_list()
	_change_primary_view("AccountList")
	return

func _connect_to_account_server(local_id: String, username: String, password: String, account_server: String, public_device_key: String, remember_me: bool = false):
	# TODO: Invalid passwords.
	# TODO: Account not found.
	# TODO: Account server unreachable.
	GlobalLogger.logs("Attempting to authorize the connection to the account server.")

	var data = {"username": username, "password": password, "pubKey": public_device_key}
	var response = await http.req(HTTPClient.Method.METHOD_POST, account_server, "/api/v1/login", 40400, ["Accept: application/json", "Content-Type: application/json"], JSON.stringify(data))
	
	# Get the private JWT for use between this device and the account server only.
	if response["ok"] == false:
		GlobalLogger.logs("Response failed for unknown reason.", 3)
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
	GlobalLogger.logs("Successfully authorized with the account server.", 1)

	# Get the public passport clients will send to everyone excluding the account server.
	# We use two "tokens" so that one can make actions on behalf of an account, 
	# and this passport just to validate we are who we say we are. This token should not be used to make any actions to the account.
	GlobalLogger.logs("Attempting to authorize this device with the provided account.")
	var device_response = await http.req(HTTPClient.Method.METHOD_POST, account_server, "/api/v1/device/auth", 40400, ["Accept: application/json", "Content-Type: application/json"], JSON.stringify(data))
	
	if device_response["ok"] == false:
		GlobalLogger.logs("Authorizing this device failed for unknown reason.", 1)
		return

	if device_response["body"] == null:
		GlobalLogger.logs("No body provided for device authorization request.", 3)
		return

	var device_response_body = JSON.parse_string(device_response["body"])

	if "error" in device_response_body.keys():
		GlobalLogger.logs("Device authorization request returned an error. '%s'" % res_body["error"], 1)
		return

	var public_account_server_passport = device_response["response_headers"]["Set-Cookie"].split("; ")
	public_account_server_passport = public_account_server_passport[0].replace("token=", "")

	# Store the tokens in memory
	CredentialStore.set_public_account_server_passport(public_account_server_passport)
	CredentialStore.set_private_account_server_jwt(private_account_server_jwt)

	if remember_me:
		# Persist if we want to be remembered.
		var _account_config = await FileManager.read_config_file("accounts", "accounts_db.cfg")
		_account_config.set_value(local_id, "private_account_server_jwt", private_account_server_jwt)
		_account_config.set_value(local_id, "public_account_server_passport", public_account_server_passport)
		_account_config.save(ACCOUNT_DATABASE_DIRECTORY)
		GlobalLogger.logs("Saved the private JWT and the passport to the account database.", 1)

	return

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
	_create_account()
	return
