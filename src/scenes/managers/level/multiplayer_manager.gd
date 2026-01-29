extends Node

@onready var scene_manager = get_tree().current_scene.get_node("SceneManager")
@onready var active_session: String = ""

func spawn_player(player):
	# FIXME: Placeholder for refactor
	while scene_manager.get_current_session_node() == null:
		await get_tree().process_frame
	
	scene_manager.get_current_session_node().call_deferred("add_child", player)

func player_exists(name: String) -> Node3D:
	# FIXME: Placeholder for refactor
	var target_node = scene_manager.get_current_session_node().get_node_or_null(name)
	
	return target_node
