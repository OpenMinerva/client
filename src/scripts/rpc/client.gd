extends Node

# Join server
# Leave server
# Kicked from server
# Banned from server

@onready var scene_manager = get_tree().current_scene.get_node("SceneManager")
@onready var network_manager = get_tree().current_scene.get_node("NetworkManager")

func connected_to_server():
	return

func connection_failed():
	return

@rpc("authority", "reliable")
func on_receive_server_info(info):
	GlobalLogger.logs("Got server info!")
	if info.level:
		await scene_manager.load_multiplayer_scene(info.level, info.level_node_name)
	get_parent().s.rpc_id(1, "on_receive_player_info", CredentialStore.info.token)
	return

@rpc("authority", "reliable")
func received_server_session_info(received_info: Dictionary) -> void:
	GlobalLogger.logs("Session information updated.")
	network_manager.info = received_info
	return