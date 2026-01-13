extends Control

@onready var network_manager = get_tree().current_scene.get_node("NetworkManager")

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
