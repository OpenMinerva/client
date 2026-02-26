extends Node

var dashboard_page_container
var dashboard_nav_container
var dashboard_home_account

const COLOR_RED = "#ff0000"
const COLOR_RED_SOFT = "#ffc8c8"
const COLOR_BLUE = "#00bbff"
const COLOR_BLUE_SOFT = "#ace1ff"
const COLOR_GREEN = "#00ff25"
const COLOR_GREEN_SOFT = "#ceffcb"
const COLOR_YELLOW = "#d0ff00"
const COLOR_YELLOW_SOFT = "#f5ffba"

var root

func init(caller_node: Node):
	root = caller_node.get_tree().current_scene
	dashboard_page_container = root.get_node("Hud2/MarginContainer/VBoxContainer/Master")
	dashboard_nav_container = root.get_node("Hud2/MarginContainer/VBoxContainer/NavBar/HBoxContainer")
	dashboard_home_account = root.get_node("Hud2/MarginContainer/VBoxContainer/Master/Home/HBoxContainer/VBoxContainer/AccountDisplay/MarginContainer/HBoxContainer")
	
	display_dashboard_section("Home")
	return

func display_account_on_home() -> void:
	GlobalLogger.logs("Displaying active account in homescreen dashboard.")

	var _account_to_display = GlobalAccount.active_account
	var _status = GlobalAccount.get_account_authentication_status(_account_to_display.get("id", ""))

	var icon_node = dashboard_home_account.get_node("Container/AspectRatioContainer/TextureRect")
	var username_node = dashboard_home_account.get_node("VBoxContainer/Username")
	var account_server_node = dashboard_home_account.get_node("VBoxContainer/AccountServer")

	var account_server_status_node = dashboard_home_account.get_node("VBoxContainer/HBoxContainer/AccountServerStatus")
	var passport_status_node = dashboard_home_account.get_node("VBoxContainer/HBoxContainer/PassportStatus")
	var account_status_node = dashboard_home_account.get_node("VBoxContainer/HBoxContainer/AccountType")

	username_node.text = _account_to_display.get("username", "")
	account_server_node.text = _account_to_display.get("account_server", "")
	
	if _status.get("valid_passport", false) == true:
		passport_status_node.get_node("HBoxContainer/Panel").get_theme_stylebox("panel").bg_color = COLOR_GREEN
		passport_status_node.get_node("HBoxContainer/AccountServer2").add_theme_color_override("font_color", COLOR_GREEN_SOFT)
	else:
		passport_status_node.get_node("HBoxContainer/Panel").get_theme_stylebox("panel").bg_color = COLOR_RED
		passport_status_node.get_node("HBoxContainer/AccountServer2").add_theme_color_override("font_color", COLOR_RED_SOFT)

	if _status.get("valid_private_jwt", false) == true:
		account_server_status_node.get_node("HBoxContainer/Panel").get_theme_stylebox("panel").bg_color = COLOR_GREEN
		account_server_status_node.get_node("HBoxContainer/AccountServer2").add_theme_color_override("font_color", COLOR_GREEN_SOFT)
	else:
		account_server_status_node.get_node("HBoxContainer/Panel").get_theme_stylebox("panel").bg_color = COLOR_RED
		account_server_status_node.get_node("HBoxContainer/AccountServer2").add_theme_color_override("font_color", COLOR_RED_SOFT)

	if _account_to_display.get("local_account", true) == true:
		account_status_node.get_node("HBoxContainer/Panel").get_theme_stylebox("panel").bg_color = COLOR_YELLOW
		account_status_node.get_node("HBoxContainer/AccountServer2").add_theme_color_override("font_color", COLOR_YELLOW_SOFT)
		account_status_node.get_node("HBoxContainer/AccountServer2").text = "Local"
	else:
		account_status_node.get_node("HBoxContainer/Panel").get_theme_stylebox("panel").bg_color = COLOR_BLUE
		account_status_node.get_node("HBoxContainer/AccountServer2").add_theme_color_override("font_color", COLOR_BLUE_SOFT)
		account_status_node.get_node("HBoxContainer/AccountServer2").text = "Cloud"

	return

func display_dashboard_section(page_name: String = "") -> void:
	# TODO: Replace variable with a list of children with names from the dashboard page list.
	if page_name not in ["Home", "SignIn", "Sessions", "SessionFocus", "Contacts", "Inventory", "Apps", "Settings", "Debug", "Exit"]:
		GlobalLogger.logs("Tried to switch to an invalid dashboard page: '%s'" % page_name)
		return

	for page in dashboard_page_container.get_children():
		# FIXME: Why do I need to format this specifically as a string like this?
		dashboard_nav_container.get_node("%s" % page.name).button_pressed = false
		page.visible = false

	var page = dashboard_page_container.get_node_or_null(page_name)
	if page:
		page.visible = true
		dashboard_nav_container.get_node("%s" % page.name).button_pressed = true
	
	return

func add_event_listeners_to_nav_buttons() -> void:
	for button in dashboard_nav_container.get_children():
		button.pressed.connect(display_dashboard_section.bind(button.name))

	return
