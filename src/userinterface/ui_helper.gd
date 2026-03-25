extends Node

var dashboard_page_container
var dashboard_nav_container
var dashboard_home_account

var dashboard_home_used_storage
var account_list_node
var create_account_button
var create_page
var create_account_back_button

const COLOR_RED = "#ff0000"
const COLOR_RED_SOFT = "#ffc8c8"
const COLOR_BLUE = "#00bbff"
const COLOR_BLUE_SOFT = "#ace1ff"
const COLOR_GREEN = "#00ff25"
const COLOR_GREEN_SOFT = "#ceffcb"
const COLOR_YELLOW = "#d0ff00"
const COLOR_YELLOW_SOFT = "#f5ffba"

var root
var tree

func init(caller_node: Node):
	root = caller_node.get_tree().current_scene
	tree = caller_node.get_tree()
	dashboard_page_container = root.get_node("Hud/MarginContainer/VBoxContainer/Master")
	dashboard_nav_container = root.get_node("Hud/MarginContainer/VBoxContainer/NavBar/HBoxContainer")
	dashboard_home_account = root.get_node("Hud/MarginContainer/VBoxContainer/Master/Home/HBoxContainer/VBoxContainer/AccountDisplay/MarginContainer/HBoxContainer")

	dashboard_home_used_storage = root.get_node("Hud/MarginContainer/VBoxContainer/Master/Home/HBoxContainer/VBoxContainer/PanelContainer2/MarginContainer/VBoxContainer")
	
	account_list_node = root.get_node("Hud/MarginContainer/VBoxContainer/Master/AccountDisplay")

	create_account_button = root.get_node("Hud/MarginContainer/VBoxContainer/Master/AccountDisplay/List/HBoxContainer/NewAccount")
	create_page = root.get_node("Hud/MarginContainer/VBoxContainer/Master/AccountCreate")
	
	display_dashboard_section("Home")
	_add_account_display_button()
	_add_event_listener_create_account_button()
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
	if page_name not in ["Home", "AccountDisplay", "AccountCreate", "Sessions", "SessionFocus", "Contacts", "Inventory", "Apps", "Settings", "Debug", "Exit"]:
		GlobalLogger.logs("Tried to switch to an invalid dashboard page: '%s'" % page_name)
		return

	for page in dashboard_page_container.get_children():
		# FIXME: Why do I need to format this specifically as a string like this?
		var dashboard_page = dashboard_page_container.get_node_or_null("%s" % page.name)
		var nav_button = dashboard_nav_container.get_node_or_null("%s" % page.name)

		if dashboard_page:
			dashboard_page.visible = false
		if nav_button:
			nav_button.button_pressed = false

	var page = dashboard_page_container.get_node_or_null(page_name)
	if page:
		var nav_button_page = dashboard_nav_container.get_node_or_null("%s" % page.name)
		page.visible = true
		if nav_button_page:
			nav_button_page.button_pressed = true
	
	match page_name:
		"Contacts":
			await tree.process_frame
			move_chat_scroll_to_bottom()

	return

func add_event_listeners_to_nav_buttons() -> void:
	var _list_of_valid_pages = dashboard_page_container.get_children()
	var _list_of_valid_pages_names = []

	for page in _list_of_valid_pages:
		_list_of_valid_pages_names.append(page.name)

	for button in dashboard_nav_container.get_children():
		if button.name in _list_of_valid_pages_names:
			button.pressed.connect(display_dashboard_section.bind(button.name))
		else:
			button.disabled = true
	return

func display_used_storage(used_bytes: int, total_bytes: int) -> void:
	dashboard_home_used_storage.get_node("ProgressBar").value = (float(used_bytes) / float(total_bytes)) * 100
	dashboard_home_used_storage.get_node("Label2").text = "%s bytes / %s bytes" % [used_bytes, total_bytes]
	return

func _add_account_display_button() -> void:
	var panel = root.get_node("Hud/MarginContainer/VBoxContainer/Master/Home/HBoxContainer/VBoxContainer/AccountDisplay")

	panel.get_node("Button").pressed.connect(display_dashboard_section.bind("AccountDisplay"))
	return

func _add_event_listener_create_account_button() -> void:
	create_account_button.pressed.connect(display_dashboard_section.bind("AccountCreate"))
	return

# TODO: This function is here as a test, it should be moved to its own file when the file is created.
func move_chat_scroll_to_bottom() -> void:
	var chat_scroll_container = root.get_node("Hud/MarginContainer/VBoxContainer/Master/Contacts/HBoxContainer/Messages/ColorRect/ScrollContainer")

	var max_scroll = chat_scroll_container.get_v_scroll_bar().max_value
	chat_scroll_container.scroll_vertical = int(max_scroll)
	return
