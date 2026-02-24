extends Node

var http = preload("res://scripts/network/http.gd").new()
var time_lib = preload("res://scripts/libs/time.gd").new()
	
const ACCOUNT_DATABASE_DIRECTORY: String = "user://database/accounts.bin"

# TODO: Create proper encryption of the account database
# https://github.com/OpenMinerva/client/issues/59
# This is just here for funsies for now.
const ENCRYPTION_KEY: String = "cb`$BaeGT12^)Zv{"

var active_account = {}
var _database = []

## Get a list of all accounts and return their information.
## @returns Array
func get_all() -> Array:
	return _database

## Adds an account to the account database.
## @returns Dictionary
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
	_clean_account.private_account_server_jwt = account.get("private_account_server_jwt", {})
	_clean_account.public_account_server_passport = account.get("public_account_server_passport", {})

	_database.append(_clean_account)
	_save_account_database()
	
	return {"ok": true, "id": account.id}

## Removes an account from the account database.
## @returns Dictionary
func remove(id: String) -> Dictionary:
	var target_entry = _database.find_custom(func(entry): return entry.get("id") == id)
	_database.remove_at(target_entry)
	_save_account_database()
	return {}

## Sets an account as the active account.
## @returns Dictionary.
func use(id: String) -> Dictionary:
	return {}

## Signs out of the active account.
## @returns void.
func clear() -> void:
	return

## Makes an attempt to authenticate an account with the accounts account server.
## @returns Dictionary
func authenticate(id: String, password: String, remember_me: bool = false) -> Dictionary:
	GlobalLogger.logs("Attempting to connect account '%s' to their account server." % id)

	var account = _get_account_by_id(id)

	# TODO: Error checks for not providing password?
	var request_data = {"username": account.username, "password": password, "pubKey": account.public_device_key}
	var response = await http.req(HTTPClient.Method.METHOD_POST, account.account_server, "/api/v1/login", 40400, ["Accept: application/json", "Content-Type: application/json"], JSON.stringify(request_data))
	
	if response["ok"] == false:
		GlobalLogger.logs("Response failed for unknown reason.", 3)
		return {}

	if response["body"] == null:
		GlobalLogger.logs("No body provided for login request.", 3)
		return {}

	var res_body = JSON.parse_string(response["body"])

	if "error" in res_body.keys():
		GlobalLogger.logs("Login request returned an error. '%s'" % res_body["error"], 1)
		return {}

	var _private_account_server_jwt = response["response_headers"]["Set-Cookie"].split("; ")
	
	var _private_token_dictionary = {
		"token": _private_account_server_jwt[0].replace("token=", ""),
		"expires": time_lib.convert_jwt_timestamp_to_unix(_private_account_server_jwt[3].replace("Expires=", ""))
	}

	_update_account_by_key(id, "private_account_server_jwt", _private_token_dictionary)

	GlobalLogger.logs("Successfully authorized login with the account server.", 1)

	await get_passport(id)
	return {}

func get_passport(id: String) -> void:
	GlobalLogger.logs("Attempting to authorize this device with the provided account.")
	var _account = _get_account_by_id(id)

	var _public_passport = {
		"token": "",
		"expires": 0
	}

	# Check if the account passport is still good.
	# Check if the account is authenticated with the account server. (If not a local account)
	# If local account, generate a new passport on our machine
	# If authenticated, send request to authorize the device
	var _request_data = {"pubKey": _account.public_device_key}
	var _device_response = await http.req(HTTPClient.Method.METHOD_POST, _account.account_server, "/api/v1/device/auth", 40400, ["Accept: application/json", "Content-Type: application/json", "Cookie: token=%s" % _account.private_account_server_jwt.token], JSON.stringify(_request_data))

	if _device_response["ok"] == false:
		GlobalLogger.logs("Authorizing this device failed for unknown reason.", 1)
		return

	if _device_response["body"] == null:
		GlobalLogger.logs("No body provided for device authorization request.", 3)
		return

	var _device_response_body = JSON.parse_string(_device_response["body"])

	if "error" in _device_response_body.keys():
		GlobalLogger.logs("Device authorization request returned an error. '%s'" % _device_response_body["error"], 1)
		return

	var _public_passport_token = _device_response["response_headers"]["Set-Cookie"].split("; ")
	_public_passport.token = _public_passport_token[0].replace("token=", "")
	_public_passport.expires = time_lib.convert_jwt_timestamp_to_unix(_public_passport_token[3].replace("Expires=", ""))

	# Record passport if successful
	_update_account_by_key(id, "public_account_server_passport", _public_passport)
	_save_account_database()
	
	return

## Save the current account database we have in memory to the disk.
func _save_account_database() -> void:
	DirAccess.open("user://").make_dir_recursive("user://database")

	# var file = FileAccess.open_encrypted(ACCOUNT_DATABASE_DIRECTORY, FileAccess.WRITE, ENCRYPTION_KEY.sha256_buffer())
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

	# var file = FileAccess.open_encrypted(ACCOUNT_DATABASE_DIRECTORY, FileAccess.READ, ENCRYPTION_KEY.sha256_buffer())
	var file = FileAccess.open(ACCOUNT_DATABASE_DIRECTORY, FileAccess.READ)

	var account_data

	if file:
		account_data = file.get_var() # Deserializes variable back
		file.close()
	
	_database = account_data
	return account_data

func _get_account_by_id(id: String) -> Dictionary:
	var index = _database.find_custom(func(entry): return entry.get("id") == id)
	return _database[index]

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
