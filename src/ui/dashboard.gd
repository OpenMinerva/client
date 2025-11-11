extends Control
var _update_session_list_timer: SceneTreeTimer = null

func _ready() -> void:
	var args = LaunchManager.get_command_line_args()
	$"MarginContainer/PanelContainer/VBoxContainer/Top/Top/User/Label".text = args.name
	Networking.connect("clients_updated", list_clients)
	start_updating_session_list()

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
	Networking.create_timer()
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

		var kick_node = user_list_item.get_node("MarginContainer/HBoxContainer/MarginContainer/Kick")
		kick_node.connect("pressed", func(): Networking.request_kick(int(client), ""))

		template_node.get_parent().add_child(user_list_item)

func clear_listed_clients():
	var template_node = $"MarginContainer/PanelContainer/VBoxContainer/Center/Center/Home/MarginContainer/HBoxContainer/VBoxContainer3/UserListTemplate"
	for child in template_node.get_parent().get_children():
		if child.name.begins_with("UserListItem_"):
			child.queue_free()
		if child.name.begins_with("@PanelContainer@"):
			child.queue_free()

func update_session_list():
	clear_session_list()
	var template_node = $"MarginContainer/PanelContainer/VBoxContainer/Center/Center/Sessions/MarginContainer/HBoxContainer/Listing/SessionListingTemplate"
	var sessions = await Networking.get_servers_from_session_server()

	for session in sessions:
		print(session)
		var session_list_item = template_node.duplicate() as Control
		session_list_item.name = "SessionListItem_%s" % str(session.id)

		var label_node = session_list_item.get_node("MarginContainer/HBoxContainer/RichTextLabel")
		if label_node:
			label_node.text = session.sessionName

		session_list_item.visible = true

		var join_node = session_list_item.get_node("MarginContainer/HBoxContainer/PanelContainer/VBoxContainer/Button")
		join_node.connect("pressed", func(): Networking.join_server(session.sessionIP))

		template_node.get_parent().add_child(session_list_item)

func clear_session_list():
	LoggerManager.log_string("Clearing the session list from the dashboard sessions", 0)
	var template_node = $"MarginContainer/PanelContainer/VBoxContainer/Center/Center/Sessions/MarginContainer/HBoxContainer/Listing/SessionListingTemplate"
	for child in template_node.get_parent().get_children():
		if child.name.begins_with("SessionListItem_"):
			LoggerManager.log_string("Removing %s from session list." % child.name, 0)
			child.queue_free()

func start_updating_session_list() -> void:
	stop_updating_session_list()
	_update_session_list_timer = get_tree().create_timer(30, false, false, true)
	_update_session_list_timer.timeout.connect(update_session_list)

func stop_updating_session_list() -> void:
	if _update_session_list_timer == null:
		return
	_update_session_list_timer.timeout.disconnect(update_session_list)
	_update_session_list_timer = null
