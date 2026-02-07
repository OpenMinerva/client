extends Control

@onready var network_manager = get_tree().current_scene.get_node("NetworkManager")
var http = preload("res://scripts/network/http.gd").new()
var keys = preload("res://scripts/crypto/keys.gd").new()

func _ready():
	while true:
		await get_tree().create_timer(1).timeout
		_update_hud_state()

func _on_join_pressed():
	await network_manager.join_server("localhost")

func set_active_state(state: bool = false):
	visible = state
	get_node("MarginContainer/VBoxContainer/PrimaryDashboard/SignIn")._render_account_list()

func _update_hud_state():
	var user_list_formatted = network_manager.info.clients.map(func(elem): return elem.username)
	%HostingBool.text = "Host: %s" % network_manager.status.hosting
	%SessionHost.text = "Server Host: %s" % network_manager.info.clients[0].username
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
		GlobalLogger.logs("Tried to switch to an invalid dashboard page: '%s'" % page_name)
		return

	for page in get_node("MarginContainer/VBoxContainer/PrimaryDashboard/").get_children():
		page.visible = false

	get_node("MarginContainer/VBoxContainer/PrimaryDashboard/%s" % page_name).visible = true
