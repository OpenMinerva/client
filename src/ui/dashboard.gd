extends Control

func _ready() -> void:
	Networking.connect("clients_updated", list_clients)

func _process(_delta) -> void:
	# Networking.NetworkStatus.server
	# Networking.NetworkStatus.client
	# Networking.NetworkStatus.host
	# Networking.NetworkStatus.port
	# Networking.NetworkStatus.max_clients
	var detailsLabel = $MarginContainer/PanelContainer/VBoxContainer/Center/Center/Home/MarginContainer/HBoxContainer/VBoxContainer2/Label
	detailsLabel.text = "Server: " + str(Networking.NetworkStatus.server) + "\nClient: " + str(Networking.NetworkStatus.client) + "\nHost: " + Networking.NetworkStatus.host + "\nPort: " + str(Networking.NetworkStatus.port)

func _on_start_server_pressed():
	# Networking.increase_server_max_clients(16)
	pass # Replace with function body.


func _on_button_pressed():
	Networking.join_server("127.0.0.1", 5996)
	pass # Replace with function body.


func _on_home_pressed():
	_close_all_dashboard_tabs()
	var home_page = $"MarginContainer/PanelContainer/VBoxContainer/Center/Center/Home"
	home_page.visible = true

func _on_sessions_pressed():
	_close_all_dashboard_tabs()
	var session_page = $"MarginContainer/PanelContainer/VBoxContainer/Center/Center/Sessions"
	session_page.visible = true

func _close_all_dashboard_tabs():
	var home_page = $"MarginContainer/PanelContainer/VBoxContainer/Center/Center/Home"
	var session_page = $"MarginContainer/PanelContainer/VBoxContainer/Center/Center/Sessions"

	home_page.visible = false
	session_page.visible = false

func list_clients():
	var template_node = $"MarginContainer/PanelContainer/VBoxContainer/Center/Center/Home/MarginContainer/HBoxContainer/VBoxContainer3/UserListTemplate"
	clear_listed_clients()

	for client in Networking.ServerInfo.users.keys():
		var user_list_item = template_node.duplicate() as Control
		user_list_item.name = "UserListItem_%s" % str(client)

		var label_node = user_list_item.get_node("MarginContainer/HBoxContainer/Username")
		if label_node:
			label_node.text = Networking.ServerInfo.users[client].name

		user_list_item.visible = true

		template_node.get_parent().add_child(user_list_item)


func clear_listed_clients():
	var template_node = $"MarginContainer/PanelContainer/VBoxContainer/Center/Center/Home/MarginContainer/HBoxContainer/VBoxContainer3/UserListTemplate"
	for child in template_node.get_parent().get_children():
		if child.name.begins_with("UserListItem_"):
			child.queue_free()
		if child.name.begins_with("@PanelContainer@"):
			child.queue_free()
