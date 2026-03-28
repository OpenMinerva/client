extends Node

var http = preload("res://scripts/network/http.gd").new()
var time_lib = preload("res://scripts/libs/time.gd").new()
var oauth_lib = preload("res://scripts/libs/oauth.gd").new()

const ACCOUNT_DATABASE_DIRECTORY: String = "user://database/accounts.bin"

# TODO: Create proper encryption of the account database
# https://github.com/OpenMinerva/client/issues/59
var stop_connection_timer = false

var active_account = {}
var _database = []

func _ready():
	oauth_lib.start_server()

## Get a list of all accounts and return their information.
func get_all() -> Array:
	return _database

## Adds an account to the account database.
func create(account: Dictionary) -> Dictionary:
	# Make sure we are only recording data we are intending on.
	var _clean_account = {}
	_clean_account.id = account.get("id", null)
	_clean_account.username = account.get("username", null)
	_clean_account.account_server = account.get("account_server", null)
	_clean_account.remember_me = account.get("remember_me", null)
	_clean_account.local_account = account.get("local_account", null)
	_clean_account.private_device_key = account.get("private_device_key", null)
	_clean_account.public_device_key = account.get("public_device_key", null)

	_database.append(_clean_account)
	_save_account_database()
	
	return {"ok": true, "id": account.id}

## Removes an account from the account database.
func remove(id: String) -> Dictionary:
	GlobalLogger.logs("Attempting to remove account '%s'" % id)
	var target_entry = _database.find_custom(func(entry): return entry.get("id") == id)
	_database.remove_at(target_entry)
	_save_account_database()
	return {"ok": true}

## Sets an account as the active account.
func use(id: String) -> void:
	GlobalLogger.logs("Setting active account to '%s'." % id, 1)
	var _account = _get_account_by_id(id)
	active_account = _account
	test_upload_public_key_to_server()
	return

## Signs out of the active account.
func clear() -> void:
	active_account = {}
	return

func authenticate(id: String, remember_me: bool = false):
	GlobalLogger.logs("Attempting to connect account '%s' to their account server." % id)
	var account = _get_account_by_id(id)

	var request_data = {"username": account.username, "rememberMe": remember_me, "account_server": account.account_server}

	oauth_lib.start_oauth_process(request_data.account_server + "/oauth/authorize")
	_try_check_connection()

func _try_check_connection():
	if oauth_lib.auth_server_url:
		stop_connection_timer = true
		return

	if stop_connection_timer == true:
		return

	var timer = get_tree().create_timer(2.0)
	timer.connect("timeout", oauth_lib.check_connection)
	await timer.timeout
	_try_check_connection()

## Save the current account database we have in memory to the disk.
func _save_account_database() -> void:
	DirAccess.open("user://").make_dir_recursive("user://database")

	var file = FileAccess.open(ACCOUNT_DATABASE_DIRECTORY, FileAccess.WRITE)

	if file:
		file.store_var(_database) # Serializes variable to binary
		file.close()
	return

## Read the account database from the config file on our disk.
func _load_account_database() -> Array:
	GlobalLogger.logs("Loading the local account database.", 1)

	var account_file_exists = await FileAccess.file_exists(ACCOUNT_DATABASE_DIRECTORY)
	if account_file_exists == false:
		GlobalLogger.logs("Account database does not exist, creating one now.", 1)
		await _save_account_database()

	var file = FileAccess.open(ACCOUNT_DATABASE_DIRECTORY, FileAccess.READ)

	var account_data

	if file:
		account_data = file.get_var() # Deserializes variable back
		file.close()
	
	_database = account_data
	return account_data

func _get_account_by_id(id: String) -> Dictionary:
	var index = _database.find_custom(func(entry): return entry.get("id") == id)

	if index > -1:
		return _database[index]

	return {}

func _update_account_by_key(id: String, key: String, value: Variant) -> void:
	var index = _database.find_custom(func(entry): return entry.get("id") == id)
	# TODO: Check if key is a valid key. 
	_database[index][key] = value
	_save_account_database()
	return

func get_account_authentication_status(id) -> Dictionary:
	var status = {
		"valid_passport": false,
		"valid_private_jwt": false
	}

	var _account = _get_account_by_id(id)

	status.valid_passport = _account.get("public_account_server_passport", {"expires": 0}).get("expires", 0) > int(Time.get_unix_time_from_system())
	status.valid_private_jwt = _account.get("private_account_server_jwt", {"expires": 0}).get("expires", 0) > int(Time.get_unix_time_from_system())

	return status

func _handle_response(response: Dictionary) -> Dictionary:
	var response_data = {"ok": false, "error": "", "body": {}}

	if response.get("ok", false) == false:
		response_data.error = "Request failed for unknown reason."
		GlobalLogger.logs(response_data.error, 3)
		return response_data

	if response.get("body", null) == null:
		response_data.error = "No body provided from the request."
		GlobalLogger.logs(response_data.error, 3)
		return response_data

	response_data.ok = true
	response_data.body = JSON.parse_string(response.get("body"))

	return response_data

# DEV: Upload public key to the server.
func test_upload_public_key_to_server():
	GlobalLogger.logs("Registering the device public key to the account server.")
	var body = {
		"public_key": active_account.public_device_key
	}
	var url_parts = UrlParser.deconstruct(active_account.account_server)
	if url_parts.ok == false:
		GlobalLogger.logs("Unhandled error registering the public device key to the account server. '%s'" % url_parts.error, 3)
		return
	url_parts = url_parts.data

	print(url_parts)

	var public_key_response = await http.req(HTTPClient.Method.METHOD_POST, url_parts.host, "/api/v1/device_key", url_parts.port, ["Accept: application/json", "Content-Type: application/json", "authorization: Bearer %s" % oauth_lib.access_token], JSON.stringify(body))
	print(public_key_response)
	return