extends Node

var root

func init(caller_node: Node) -> void:
	root = caller_node.get_tree().current_scene.get_node("Hud2/MarginContainer/VBoxContainer/Master/AccountDisplay")

func render_account_list() -> void:
	var _list = GlobalAccount.get_all()
	var _template = root.get_node("Templates/Account")
	var _account_list_node = root.get_node("List/ScrollContainer/AccountList")

	_clear_account_list()

	for local_account in _list:
		var _account_listing = _template.duplicate()

		var _username_node = _account_listing.get_node("MarginContainer/HBoxContainer/VBoxContainer/Username")
		var _account_server_node = _account_listing.get_node("MarginContainer/HBoxContainer/VBoxContainer/AccountServer")
		var _login_button = _account_listing.get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Login")
		var _configure_button = _account_listing.get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Configure")
		var _remove_button = _account_listing.get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Remove")

		_username_node.text = local_account.username
		_account_server_node.text = local_account.account_server

		_remove_button.pressed.connect(_handle_remove_account.bind(local_account.id))

		_account_list_node.add_child(_account_listing)

	return


func _clear_account_list() -> void:
	var _account_list_node = root.get_node("List/ScrollContainer/AccountList")
	for _entry in _account_list_node.get_children():
		_entry.queue_free()
	return

func _handle_remove_account(account_id: String) -> void:
	# TODO: Instead of rendering the whole list again, just remove that singular entry?
	await GlobalAccount.remove(account_id)
	render_account_list()
	return