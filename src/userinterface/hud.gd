extends Control

@onready var network_manager = get_tree().current_scene.get_node("NetworkManager")
var http = preload("res://scripts/http.gd").new()
var keys = preload("res://scripts/keys.gd").new()

func _ready():
	while true:
		await get_tree().create_timer(1).timeout
		_update_hud_state()

func _on_join_pressed():
	await network_manager.join_server("localhost")

func set_active_state(state: bool = false):
	visible = state

func _update_hud_state():
	var user_list_formatted = network_manager.info.clients.map(func(elem): return elem.display_name)
	%HostingBool.text = "Host: %s" % network_manager.status.hosting
	%SessionHost.text = "Server Host: %s" % network_manager.info.clients[0].display_name
	%ClientBool.text = "Client: %s" % network_manager.status.client
	%ConnectedUserCount.text = "Total Users: %s" % len(network_manager.info.clients)
	%UserList.text = "User List: %s" % ", ".join(user_list_formatted)


func _on_nav_exit_pressed():
	_show_dashboard_page("Exit")

func _on_nav_debug_pressed():
	_show_dashboard_page("Debug")

func _on_nav_inventory_pressed():
	_show_dashboard_page("Inventory")

func _on_nav_contacts_pressed():
	_show_dashboard_page("Contacts")

func _on_nav_sessions_pressed():
	_show_dashboard_page("Sessions")

func _on_nav_home_pressed():
	_show_dashboard_page("Home")

func _show_dashboard_page(page_name: String = "Home"):
	if page_name not in ["Home", "Sessions", "Contacts", "Inventory", "Debug", "Exit"]:
		GlobalLogger.log_string("Tried to switch to an invalid dashboard page: '%s'" % page_name)
		return

	for page in get_node("MarginContainer/VBoxContainer/PrimaryDashboard/").get_children():
		page.visible = false

	get_node("MarginContainer/VBoxContainer/PrimaryDashboard/%s" % page_name).visible = true

func _on_login_button_pressed():
	var username_field_value = $"MarginContainer/VBoxContainer/PrimaryDashboard/SignIn/Panel/MarginContainer/VBoxContainer/UsernameField".text
	var password_field_value = $"MarginContainer/VBoxContainer/PrimaryDashboard/SignIn/Panel/MarginContainer/VBoxContainer/PasswordField".text
	var data = {"username": username_field_value, "password": password_field_value, "scope": "appAuth"}
	# TODO: Make sure we have a keypair generated
	
	var keyPair = keys.read_keys_from_disk(username_field_value)
	data["pubKey"] = keyPair[0]

	# TODO: Replace localhost with proper account server url + port
	var response = await http.req(HTTPClient.Method.METHOD_POST, "http://localhost", "/api/v1/device/auth", 40400, ["Accept: application/json", "Content-Type: application/json"], JSON.stringify(data))
	
	if response["ok"] == false:
		GlobalLogger.log_string("Response failed for unknown reason.", 1)
		return

	if response["body"] == null:
		GlobalLogger.log_string("No body provided for login request.", 3)
		return

	var res_body = JSON.parse_string(response["body"])

	if "error" in res_body.keys():
		GlobalLogger.log_string("Login request returned an error. '%s'" % res_body["error"], 1)
		return
		
	var token = response["response_headers"]["Set-Cookie"].split("; ")
	token[0] = token[0].replace("token=", "")
	CredentialStore.set_account_credential(token)
	_show_dashboard_page("Home")