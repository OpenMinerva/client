extends Control

var ui_helper = preload("res:///userinterface/ui_helper.gd").new()
var ui_account_create = preload("res:///userinterface/account_create.gd").new()
var ui_account_display = preload("res:///userinterface/account_display.gd").new()

func _ready():
	await GlobalAccount._load_account_database()
	await ui_helper.init(self )
	await ui_account_create.init(self )
	await ui_account_display.init(self )

	ui_helper.add_event_listeners_to_nav_buttons()
	ui_helper.display_account_on_home()
	ui_helper.display_used_storage(512, 1024)

	_add_button_event_listeners()
	ui_account_display.render_account_list()

	ui_helper.move_chat_scroll_to_bottom()
	return

func set_active_state(state: bool) -> void:
	visible = state
	return
func _add_button_event_listeners() -> void:
	var create_account_confirm = get_node("MarginContainer/VBoxContainer/Master/AccountCreate/Create/OAuth/Create/HBoxContainer/ConfirmCreateAccount")
	await create_account_confirm.pressed.connect(_handle_add_account)

	var create_account_usernamepassword_back = get_node("MarginContainer/VBoxContainer/Master/AccountCreate/Create/UsernamePassword/Create/HBoxContainer/CreateAccountBack")
	await create_account_usernamepassword_back.pressed.connect(_handle_reset_account_create_dash)

	var create_account_oauth_back = get_node("MarginContainer/VBoxContainer/Master/AccountCreate/Create/OAuth/Create/HBoxContainer/CreateAccountBack")
	await create_account_oauth_back.pressed.connect(_handle_reset_account_create_dash)

	ui_account_display.using_account.connect(ui_helper.display_account_on_home)
	return

func _handle_add_account() -> void:
	await ui_account_create.create_account()
	ui_account_create.clear_form()
	ui_account_display.render_account_list()
	return

func _handle_reset_account_create_dash() -> void:
	ui_account_create.reset_root()
	return
