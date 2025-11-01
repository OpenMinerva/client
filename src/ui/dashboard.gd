extends Control

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
