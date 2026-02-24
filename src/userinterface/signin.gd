extends Node

var rsa = preload("res://scripts/crypto/rsa.gd").new()
var http = preload("res://scripts/network/http.gd").new()
var random = preload("res://scripts/utils/random.gd").new()

const ACCOUNT_DATABASE_DIRECTORY = "user://config/accounts/accounts_db.cfg"

enum _message_type {NORMAL, ERROR, SUCCESS}

func _ready():
	await GlobalAccount._load_account_database()
	_render_account_list()
	return

func _render_account_list():
	_clear_account_list()

	var _all_accounts: Array = await GlobalAccount.get_all()

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

	# Account status indicators
	var _auth_status = GlobalAccount.get_account_authentication_status(account.id)

	account_button.get_node("HBoxContainer/MarginContainer/AccountStatus").color = "#ff0000"

	if _auth_status.valid_private_jwt == true:
		account_button.get_node("HBoxContainer/MarginContainer/AccountStatus").color = "#ffff00"

	if _auth_status.valid_passport == true:
		account_button.get_node("HBoxContainer/MarginContainer/AccountStatus").color = "#00ff00"

	# Insert the account into our list.
	account_list_container_node.add_child(account_button)
	account_button.visible = true
	return

func _login(local_id: String):
	GlobalAccount.use(local_id)
	
func _delete_account(local_id: String):
	GlobalAccount.remove(local_id)
	return

func _create_account() -> void:
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
		"private_account_server_jwt": {"token": "", "expires": 0},
		"public_account_server_passport": {"token": "", "expires": 0}
	}
	GlobalAccount.create(_account_dictionary)

	if local_account == false && account_server != "":
		GlobalAccount.authenticate(local_id, password, remember_me)

	_render_account_list()
	_change_primary_view("AccountList")
	return

# Buttons:
# These just initiate the functions otherwise in this file
func _on_add_account_pressed():
	_change_primary_view("CreateLocalAccount")
	return

func _change_primary_view(target_node_name: String):
	for view in get_node("Panel").get_children():
		view.visible = false

	if target_node_name == "AccountList":
		_render_account_list()

	get_node("Panel/%s" % target_node_name).visible = true
	return

func _on_back_from_create_local_account_pressed():
	_change_primary_view("AccountList")
	# TODO: Clear line entries
	return

func _on_create_local_account_button_pressed():
	_create_account()
	return
