# --- License
# File: /client/src/scripts/libs/account.gd
# Project: OpenMinerva
# Created Date: 26 February 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Node

const ACCOUNT_DATABASE_DIRECTORY: String = "user://database/accounts.bin"
const ACCOUNT_DATABASE_TEMPLATE: Dictionary = {
	"id": "",
	"display_name": "",
	"keys": {
		"private": "",
		"public": "",
	},
	"auth_type": Enum.AccountLoginType.NULL,
	"auth": { },
}
const ACCOUNT_DATABASE_OAUTH_TEMPLATE: Dictionary = {
	"id": "",
	"expirey": 0,
	"access_token": "",
	"refresh_token": "",
}

var time_lib = preload("res://scripts/libs/time.gd").new()
var random_lib = preload("res://scripts/utils/random.gd").new()
var rsa_lib = preload("res://scripts/crypto/rsa.gd").new()
# TODO: Create proper encryption of the account database
# https://github.com/OpenMinerva/client/issues/59
var stop_connection_timer = false
var active_account = { }
var dev_session_server_api_key = ""
var _database: Dictionary = { }


func _ready():
	_load_account_database()


## Get a list of all accounts and return their information.
func get_all() -> Array[Dictionary]:
	var _return_value: Array[Dictionary] = []
	for _account_id in _database.keys():
		var _account = _database.get(_account_id)
		_return_value.append(_account)
	return _return_value


## Adds an account to the account database.
func create(account: Dictionary, type: String) -> Dictionary:
	# Make sure we are only recording data we are intending on.
	var account_formatted: Dictionary = { }

	if type == "oauth":
		account_formatted = _create_oauth(account)

	if len(account_formatted.keys()) == 0:
		GlobalLogger.log("Tried to create an account, but there was nothing to save.", Enum.LogLevel.ERROR)
		return { "ok": false, "error": "No account formatted.", "id": null }

	_database.set(account_formatted.id, account_formatted)

	_save_account_database()

	Events.emit_signal("dash_account_list_loaded")
	return { "ok": true, "id": account_formatted.id }


## Removes an account from the account database.
func remove(id: String) -> Dictionary:
	GlobalLogger.log("Attempting to remove account '%s'" % id)
	_database.erase(id)
	_save_account_database()

	Events.emit_signal("dash_account_list_loaded")

	return { "ok": true }


## Sets an account as the active account.
func use(id: String) -> void:
	GlobalLogger.log("Setting active account to '%s'." % id, Enum.LogLevel.INFO)
	var _account = _database.get(id)

	# TODO: Error checking
	var url = UrlParser.deconstruct(_account.account_server)
	url = url.data

	var _oauth = OAuth2Client.new(
		url.host,
		url.port,
		"OpenMinerva-Game-Client",
		54000,
		GlobalLogger,
		HTTP,
		true,
	)

	if _account.type == Enum.AccountLoginType.OAUTH:
		var _oauth_valid: Dictionary = await _oauth.validate(_account.auth)

		if _oauth_valid.ok == OAuth2Client.OAUTH2_CLIENT_RESULT.OK && _oauth_valid.data == false:
			await authenticate_oauth(id)

	active_account = _account
	Events.emit_signal("dash_active_account_changed", active_account)
	return


## Signs out of the active account.
func clear() -> void:
	active_account = { }
	return


func update(id: String, data: Dictionary) -> void:
	var _account = _database.get(id)

	var _database_keys = _account.keys()
	var _data_keys = data.keys()

	for key in _data_keys:
		if key not in _database_keys:
			GlobalLogger.log("Tried to update an invalid key in an account, '%s'." % key, Enum.LogLevel.WARNING)
			continue

		_account[key] = data[key]

	_database.set(id, _account)
	_save_account_database()
	return


func authenticate_oauth(id: String, _remember_me: bool = false) -> void:
	# TODO: Error checks
	GlobalLogger.log("Attempting to connect account '%s' using oauth." % id)

	var _account = _database.get(id)

	# TODO: Check if account is still valid without trying to sign in.
	var url = UrlParser.deconstruct(_account.account_server)
	url = url.data

	var _oauth = OAuth2Client.new(
		url.host,
		url.port,
		"OpenMinerva-Game-Client",
		54000,
		GlobalLogger,
		HTTP,
		true,
	)

	var oauth_tokens = await _oauth.authenticate()
	if oauth_tokens.ok == OAuth2Client.OAUTH2_CLIENT_RESULT.OK:
		update(id, { "auth": oauth_tokens.data })

	return


func get_account_authentication_status(id) -> Dictionary:
	var status = {
		"valid_passport": false,
		"valid_private_jwt": false,
	}

	var _account = _database.get(id)

	status.valid_passport = _account.get("public_account_server_passport", { "expires": 0 }).get("expires", 0) > int(Time.get_unix_time_from_system())
	status.valid_private_jwt = _account.get("private_account_server_jwt", { "expires": 0 }).get("expires", 0) > int(Time.get_unix_time_from_system())

	return status


func _create_oauth(account) -> Dictionary:
	var _account_keys = rsa_lib.generate_keypair()
	var _account_authentication: Dictionary = { }
	var _account = ACCOUNT_DATABASE_TEMPLATE.duplicate()
	_account.set("id", random_lib.random_string(6, true))
	_account.set("display_name", account.get("display_name", null))
	_account.set("account_server", account.get("account_server", null))
	_account.keys.set("public", _account_keys.public)
	_account.keys.set("private", _account_keys.private)

	_account.set("type", Enum.AccountLoginType.OAUTH)

	_account.set("auth", ACCOUNT_DATABASE_OAUTH_TEMPLATE)

	return _account


## Save the current account database we have in memory to the disk.
func _save_account_database() -> void:
	GlobalLogger.log("Saving account database to disk.")
	DirAccess.open("user://").make_dir_recursive("user://database")

	var file = FileAccess.open(ACCOUNT_DATABASE_DIRECTORY, FileAccess.WRITE)
	if file:
		file.store_var(_database) # Serializes variable to binary
		file.close()
	return


## Read the account database from the config file on our disk.
func _load_account_database() -> Dictionary:
	GlobalLogger.log("Loading the local account database.", Enum.LogLevel.INFO)

	var account_file_exists = FileAccess.file_exists(ACCOUNT_DATABASE_DIRECTORY)
	if account_file_exists == false:
		GlobalLogger.log("Account database does not exist, creating one now.", Enum.LogLevel.INFO)
		_save_account_database()

	var file = FileAccess.open(ACCOUNT_DATABASE_DIRECTORY, FileAccess.READ)

	var account_data: Dictionary = { }

	if file:
		var _file_contents = file.get_var()

		if _file_contents == null:
			account_data = { }
		else:
			account_data = _file_contents # Deserializes variable back

		file.close()

	_database = account_data
	return account_data


func _update_account_by_key(id: String, key: String, value: Variant) -> void:
	# TODO: Check if key is a valid key.
	# TODO: This is unsafe.
	_database.get(id).set(key, value)
	_save_account_database()
	return


func _handle_response(response: Dictionary) -> Dictionary:
	var response_data = { "ok": false, "error": "", "body": { } }

	if response.get("ok", false) == false:
		response_data.error = "Request failed for unknown reason."
		GlobalLogger.log(response_data.error, Enum.LogLevel.ERROR)
		return response_data

	if response.get("body", null) == null:
		response_data.error = "No body provided from the request."
		GlobalLogger.log(response_data.error, Enum.LogLevel.ERROR)
		return response_data

	response_data.ok = true
	response_data.body = JSON.parse_string(response.get("body"))

	return response_data
